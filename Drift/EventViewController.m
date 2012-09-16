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

@interface EventViewController ()

@property (nonatomic) NSDateFormatter *startDateFormatter;
@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSDateComponents *previousNowComponents;
@property (nonatomic) Event *currentEvent;

@end

@implementation EventViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

    [self reset];

    NSArray *events = [Event all];
    if (events) {
        self.currentEvent = [[events sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:0];
    }

    self.startDateFormatter = [[NSDateFormatter alloc] init];
    [self.startDateFormatter setDateFormat:@"HH:mm '@' d LLL, y"];

    self.calendar = [NSCalendar currentCalendar];

    // Scale down the startDate and stopDate
    self.startDateLabel.layer.transform = CATransform3DMakeScale(0.6f, 0.6f, 1);
    self.stopDateLabel.layer.transform = CATransform3DMakeScale(0.6f, 0.6f, 1);

	// Get notified of new things happening
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(handleDataModelChange:)
	                                             name:NSManagedObjectContextDidSaveNotification
	                                           object:[[CoreDataManager instance] managedObjectContext]];

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
    if ([self.currentEvent isActive]) {
        [self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];
    } else {
        [self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];
    }

	if (self.currentEvent) {
        [self.eventTimerControl startWithEvent:self.currentEvent];
	} else {
        [self reset];
    }
}

#pragma mark -
#pragma mark Public methods

- (IBAction)toggleEvent:(id)sender {
	NSDate *now = [NSDate date];

	if ([self.currentEvent isActive]) {
		[TestFlight passCheckpoint:@"STOP EVENT"];

		self.currentEvent.stopDate = now;

        [self.eventTimerControl stop];

		// Toggle button to start state
		[self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];
	} else {
		[TestFlight passCheckpoint:@"START EVENT"];

        [self reset];

		// No, lets create a new one
        self.currentEvent = [Event create];
		self.currentEvent.startDate = now;

		[self.eventTimerControl startWithEvent:self.currentEvent];

		// Toggle button to stop state
		[self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];
	}

    [[CoreDataManager instance] saveContext];
}

#pragma mark -
#pragma mark Private methods

- (void)reset {
    [self.eventTimerControl reset];

    self.currentEvent = nil;

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
    if (date) {
        static NSUInteger unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;

        NSDateComponents *components = [self.calendar components:unitFlags fromDate:self.currentEvent.startDate toDate:date options:0];

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

- (void)handleDataModelChange:(NSNotification *)note {
	NSSet *deletedObjects = [[note userInfo] objectForKey:NSDeletedObjectsKey];
    if (deletedObjects) {
        NSArray *deletedEvents = [deletedObjects allObjects];

        NSUInteger index = [deletedEvents indexOfObject:self.currentEvent];

        if (index != NSNotFound) {
            [self reset];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"startDate"]) {
		NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];
        self.currentEvent.startDate = date;

		[self updateStartLabelWithDate:date];
	} else if ([keyPath isEqualToString:@"nowDate"]) {
		NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];

		[self updateNowLabelWithDate:date];
	} else if ([keyPath isEqualToString:@"stopDate"]) {
		NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];
        self.currentEvent.stopDate = date;

		[self updateStopLabelWithDate:date];
	} else if ([keyPath isEqualToString:@"isTransforming"]) {
        EventTimerTransformingEnum isTransforming = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (isTransforming == EventTimerTransformingStartDateStart) {
            [self animateStartDateIsTransforming:YES];
            [self animateTimeRunningIsTransforming:YES];
        } else if (isTransforming == EventTimerTransformingStopDateStart) {
            [self animateStopDateIsTransforming:YES];
            [self animateTimeRunningIsTransforming:YES];
        } else if (isTransforming == EventTimerTransformingStartDateStop) {
            [self animateStartDateIsTransforming:NO];
            [self animateTimeRunningIsTransforming:NO];

            [[CoreDataManager instance] saveContext];
        } else if (isTransforming == EventTimerTransformingStopDateStop) {
            [self animateStopDateIsTransforming:NO];
            [self animateTimeRunningIsTransforming:NO];

            [[CoreDataManager instance] saveContext];
        }
    }
}

@end