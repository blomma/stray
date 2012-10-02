//
//  EventViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "NSManagedObject+ActiveRecord.h"
#import "TagViewController.h"
#import "Tag.h"
#import "DataManager.h"
#import "Change.h"

@interface EventViewController ()

@property (nonatomic) NSDateFormatter *startDateFormatter;
@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSDateComponents *previousNowComponents;

@end

@implementation EventViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

    [self reset];

    self.startDateFormatter = [[NSDateFormatter alloc] init];
    [self.startDateFormatter setDateFormat:@"HH:mm '@' d LLL, y"];

    self.calendar = [NSCalendar currentCalendar];

    // Scale down the startDate and stopDate
    self.startDateLabel.layer.transform = CATransform3DMakeScale(0.6f, 0.6f, 1);
    self.stopDateLabel.layer.transform = CATransform3DMakeScale(0.6f, 0.6f, 1);

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(dataModelDidSave:)
	                                             name:kDataManagerDidSaveNotification
	                                           object:[DataManager instance]];

	[self.eventTimerControl addObserver:self
	                         forKeyPath:@"startDate"
	                            options:NSKeyValueObservingOptionNew
	                            context:NULL];

	[self.eventTimerControl addObserver:self
	                         forKeyPath:@"nowDate"
	                            options:NSKeyValueObservingOptionNew
	                            context:NULL];

	[self.eventTimerControl addObserver:self
	                         forKeyPath:@"stopDate"
	                            options:NSKeyValueObservingOptionNew
	                            context:NULL];

	[self.eventTimerControl addObserver:self
	                         forKeyPath:@"isTransforming"
	                            options:NSKeyValueObservingOptionNew
	                            context:NULL];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    Event *event = [DataManager instance].state.inEvent;
    
    if ([event isActive]) {
        [self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];
    } else {
        [self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];
    }

	if (event) {
        [self.eventTimerControl startWithEvent:event];

        NSString *tagName = event.inTag ? event.inTag.name : @"";
        [self.tag setTitle:tagName forState:UIControlStateNormal];
	} else {
        [self reset];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    Event *event = [[DataManager instance] state].inEvent;

    TagViewController *tagViewController = [segue destinationViewController];
    tagViewController.event = event;
}

#pragma mark -
#pragma mark Public methods

- (IBAction)toggleEvent:(id)sender {
	NSDate *now = [NSDate date];

    Event *event = [DataManager instance].state.inEvent;

	if ([event isActive]) {
		[TestFlight passCheckpoint:@"STOP EVENT"];

		event.stopDate = now;

        [self.eventTimerControl stop];

		// Toggle button to start state
		[self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];
	} else {
		[TestFlight passCheckpoint:@"START EVENT"];

        [self reset];

        event = [Event create];
		event.startDate = now;

        [DataManager instance].state.inEvent = event;

        [self.eventTimerControl startWithEvent:event];

		// Toggle button to stop state
		[self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];
	}

    [[CoreDataManager instance] saveContext];
}

#pragma mark -
#pragma mark Private methods

- (void)reset {
    [self.eventTimerControl reset];

    [self.tag setTitle:@"" forState:UIControlStateNormal];

    self.startDateLabel.text   = @"";
    self.runningTimeLabel.text = @"00:00:00";
    self.stopDateLabel.text    = @"";
}

- (void)updateStartLabelWithDate:(NSDate *)date {
    if (date) {
        self.startDateLabel.text = [self.startDateFormatter stringFromDate:date];
    }
}

- (void)updateNowLabelWithDate:(NSDate *)date {
    Event *event = [DataManager instance].state.inEvent;

    if (date && event) {
        static NSUInteger unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;

        NSDateComponents *components = [self.calendar components:unitFlags fromDate:event.startDate toDate:date options:0];

        if (components.hour != self.previousNowComponents.hour
            || components.minute != self.previousNowComponents.minute
            || components.second != self.previousNowComponents.second) {
            self.runningTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", components.hour, components.minute, components.second];
            self.previousNowComponents = components;
        }
    }
}

- (void)updateStopLabelWithDate:(NSDate *)date {
	self.stopDateLabel.text = [self.startDateFormatter stringFromDate:date];
}

- (void)animateTimeRunningIsTransforming:(BOOL)isTransforming {
    if (isTransforming) {
        // Create the keyframe animation object
        CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];

        // Create the transform; we'll scale x and y by 1.5, leaving z alone
        // since this is a 2D animation.
        CATransform3D transform = CATransform3DMakeScale(.3f, .3f, 1); // Scale in x and y

        // Add the keyframes.  Note we have to start and end with CATransformIdentity,
        // so that the label starts from and returns to its non-transformed state.
        [scaleAnimation setValues:@[
         [NSValue valueWithCATransform3D:CATransform3DIdentity],
         [NSValue valueWithCATransform3D:transform]
         ]];

        // set the duration of the animation
        [scaleAnimation setDuration: .3];

        scaleAnimation.fillMode = kCAFillModeForwards;
        scaleAnimation.removedOnCompletion = NO;

        // animate your label layer = rock and roll!
        [[self.runningTimeLabel layer] addAnimation:scaleAnimation forKey:@"scaleText"];
    } else {
        // Create the keyframe animation object
        CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];

        // Create the transform; we'll scale x and y by 1.5, leaving z alone
        // since this is a 2D animation.
        CATransform3D transform = CATransform3DMakeScale(.3f, .3f, 1); // Scale in x and y

        // Add the keyframes.  Note we have to start and end with CATransformIdentity,
        // so that the label starts from and returns to its non-transformed state.
        [scaleAnimation setValues:@[
         [NSValue valueWithCATransform3D:transform],
         [NSValue valueWithCATransform3D:CATransform3DIdentity]
         ]];

        // set the duration of the animation
        [scaleAnimation setDuration: .3];

        // animate your label layer = rock and roll!
        [[self.runningTimeLabel layer] addAnimation:scaleAnimation forKey:@"scaleText"];
    }
}

- (void)animateStartDateIsTransforming:(BOOL)isTransforming {
    if (isTransforming) {
        // Create the keyframe animation object
        CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];

        // Create the transform; we'll scale x and y by 1.5, leaving z alone
        // since this is a 2D animation.
        CATransform3D transform = CATransform3DMakeScale(1, 1, 1); // Scale in x and y

        // Add the keyframes.  Note we have to start and end with CATransformIdentity,
        // so that the label starts from and returns to its non-transformed state.
        [scaleAnimation setValues:@[
         [NSValue valueWithCATransform3D:self.startDateLabel.layer.transform],
         [NSValue valueWithCATransform3D:transform]
         ]];

        // set the duration of the animation
        [scaleAnimation setDuration: .3];

        scaleAnimation.fillMode = kCAFillModeForwards;
        scaleAnimation.removedOnCompletion = NO;

        // animate your label layer = rock and roll!
        [[self.startDateLabel layer] addAnimation:scaleAnimation forKey:@"scaleText"];
    } else {
        // Create the keyframe animation object
        CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];

        // Create the transform; we'll scale x and y by 1.5, leaving z alone
        // since this is a 2D animation.
        CATransform3D transform = CATransform3DMakeScale(0.6f, 0.6f, 1); // Scale in x and y

        // Add the keyframes.  Note we have to start and end with CATransformIdentity,
        // so that the label starts from and returns to its non-transformed state.
        [scaleAnimation setValues:@[
         [NSValue valueWithCATransform3D:CATransform3DIdentity],
         [NSValue valueWithCATransform3D:transform],
         ]];

        // set the duration of the animation
        [scaleAnimation setDuration: .3];

        // animate your label layer = rock and roll!
        [[self.startDateLabel layer] addAnimation:scaleAnimation forKey:@"scaleText"];
    }
}

- (void)animateStopDateIsTransforming:(BOOL)isTransforming {
    if (isTransforming) {
        // Create the keyframe animation object
        CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];

        // Create the transform; we'll scale x and y by 1.5, leaving z alone
        // since this is a 2D animation.
        CATransform3D transform = CATransform3DMakeScale(1, 1, 1); // Scale in x and y

        // Add the keyframes.  Note we have to start and end with CATransformIdentity,
        // so that the label starts from and returns to its non-transformed state.
        [scaleAnimation setValues:@[
         [NSValue valueWithCATransform3D:self.stopDateLabel.layer.transform],
         [NSValue valueWithCATransform3D:transform]
         ]];

        // set the duration of the animation
        [scaleAnimation setDuration: .3];

        scaleAnimation.fillMode = kCAFillModeForwards;
        scaleAnimation.removedOnCompletion = NO;

        // animate your label layer = rock and roll!
        [[self.stopDateLabel layer] addAnimation:scaleAnimation forKey:@"scaleText"];
    } else {
        // Create the keyframe animation object
        CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];

        // Create the transform; we'll scale x and y by 1.5, leaving z alone
        // since this is a 2D animation.
        CATransform3D transform = CATransform3DMakeScale(0.6f, 0.6f, 1); // Scale in x and y

        // Add the keyframes.  Note we have to start and end with CATransformIdentity,
        // so that the label starts from and returns to its non-transformed state.
        [scaleAnimation setValues:@[
         [NSValue valueWithCATransform3D:CATransform3DIdentity],
         [NSValue valueWithCATransform3D:transform],
         ]];

        // set the duration of the animation
        [scaleAnimation setDuration: .3];

        // animate your label layer = rock and roll!
        [[self.stopDateLabel layer] addAnimation:scaleAnimation forKey:@"scaleText"];
    }
}

- (void)dataModelDidSave:(NSNotification *)note {
    Event *event = [DataManager instance].state.inEvent;

	NSSet *eventChangeObjects = [[note userInfo] objectForKey:kEventChangesKey];
    NSArray *deletedEvents = [[eventChangeObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        Change *change = (Change *)obj;
        return [change.type isEqualToString:ChangeDelete] && [change.object isEqual:event];
    }] allObjects];

    DLog(@"eventChangeObjects %@", eventChangeObjects);
    DLog(@"deletedEvents %@", deletedEvents);

    if (deletedEvents.count > 0) {
        [DataManager instance].state.inEvent = nil;

        [self reset];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    Event *event = [DataManager instance].state.inEvent;

	if ([keyPath isEqualToString:@"startDate"]) {
		NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];
        event.startDate = date;

		[self updateStartLabelWithDate:date];
	} else if ([keyPath isEqualToString:@"nowDate"]) {
		NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];

		[self updateNowLabelWithDate:date];
	} else if ([keyPath isEqualToString:@"stopDate"]) {
		NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];
        event.stopDate = date;

		[self updateStopLabelWithDate:date];
	} else if ([keyPath isEqualToString:@"isTransforming"]) {
        EventTimerTransformingEnum isTransforming = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (isTransforming == EventTimerStartDateTransformingStart) {
            [self animateStartDateIsTransforming:YES];
            [self animateTimeRunningIsTransforming:YES];
        } else if (isTransforming == EventTimerStopDateTransformingStart) {
            [self animateStopDateIsTransforming:YES];
            [self animateTimeRunningIsTransforming:YES];
        } else if (isTransforming == EventTimerStartDateTransformingStop) {
            [self animateStartDateIsTransforming:NO];
            [self animateTimeRunningIsTransforming:NO];

            [[CoreDataManager instance] saveContext];
        } else if (isTransforming == EventTimerStopDateTransformingStop) {
            [self animateStopDateIsTransforming:NO];
            [self animateTimeRunningIsTransforming:NO];

            [[CoreDataManager instance] saveContext];
        }
    }
}

@end