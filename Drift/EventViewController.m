//
//  EventViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventDataManager.h"
#import "EventViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface EventViewController ()

@property (nonatomic) NSDateFormatter *startDateFormatter;
@property (nonatomic) NSCalendar *calendar;

@property (nonatomic) NSDateComponents *previousNowComponents;
@end

@implementation EventViewController

#pragma mark -
#pragma mark Application lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
        // Startdate formatter
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"HH:mm '@' d LLL, y"];
        self.startDateFormatter = formatter;

        self.calendar = [NSCalendar currentCalendar];
}

	return self;
}

- (void)viewWillAppear:(BOOL)animated {
	Event *currentEvent = [[EventDataManager sharedManager] currentEvent];

	if (currentEvent) {
		[self updateStartLabel:currentEvent.startDate];

		if (currentEvent.isActiveValue) {
			[self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];
			[self.eventTimerControl startWithDate:currentEvent.startDate];
		} else {
			[self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];

			self.eventTimerControl.startDate = currentEvent.startDate;
			self.eventTimerControl.nowDate   = currentEvent.stopDate;
			self.eventTimerControl.stopDate  = currentEvent.stopDate;

			[self updateNowLabel:currentEvent.stopDate];
		}
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];

    // Scale down the startDate
    self.startDateLabel.layer.transform = CATransform3DMakeScale(0.6f, 0.6f, 1); // Scale in x and y

	[self.eventTimerControl addObserver:self
	                         forKeyPath:@"startDate"
	                            options:NSKeyValueObservingOptionNew
	                            context:NULL];

	[self.eventTimerControl addObserver:self
	                         forKeyPath:@"nowDate"
	                            options:NSKeyValueObservingOptionNew
	                            context:NULL];

	[self.eventTimerControl addObserver:self
	                         forKeyPath:@"isTransforming"
	                            options:NSKeyValueObservingOptionNew
	                            context:NULL];
}

#pragma mark -
#pragma mark Public instance methods

- (IBAction)toggleEvent:(id)sender {
	Event *currentEvent = [[EventDataManager sharedManager] currentEvent];

	NSDate *now         = [NSDate date];

	// Do we have a event that is running
	if (currentEvent.isActiveValue) {
		[TestFlight passCheckpoint:@"STOP EVENT"];

		currentEvent.isActiveValue = NO;
		currentEvent.stopDate     = now;

		// Stop the face
		[self.eventTimerControl stopWithDate:now];

		// Toggle button to start state
		[self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];
	} else {
		[TestFlight passCheckpoint:@"START EVENT"];

		// No, lets create a new one
		currentEvent               = [[EventDataManager sharedManager] createEvent];
		currentEvent.isActiveValue = YES;
		currentEvent.startDate     = now;

		// Start up the face
		[self.eventTimerControl startWithDate:now];

		// Toggle button to stop state
		[self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];
	}

	[[EventDataManager sharedManager] persistCurrentEvent];
}

#pragma mark -
#pragma mark Private Instance methods

- (void)updateStartLabel:(NSDate *)date {
	self.startDateLabel.text = [self.startDateFormatter stringFromDate:date];
}

- (void)updateNowLabel:(NSDate *)date {
	Event *event = [[EventDataManager sharedManager] currentEvent];

	unsigned int static unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	NSDateComponents *components = [self.calendar components:unitFlags fromDate:event.startDate toDate:date options:0];

    if (components.hour != self.previousNowComponents.hour || components.minute != self.previousNowComponents.minute || components.second != self.previousNowComponents.second) {
        self.runningTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", components.hour, components.minute, components.second];
        self.previousNowComponents = components;
    }
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
        [scaleAnimation setValues:[NSArray arrayWithObjects:
                                   [NSValue valueWithCATransform3D:CATransform3DIdentity],
                                   [NSValue valueWithCATransform3D:transform],
                                   nil]];

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
        [scaleAnimation setValues:[NSArray arrayWithObjects:
                                   [NSValue valueWithCATransform3D:transform],
                                   [NSValue valueWithCATransform3D:CATransform3DIdentity],
                                   nil]];

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
        [scaleAnimation setValues:[NSArray arrayWithObjects:
                                   [NSValue valueWithCATransform3D:self.startDateLabel.layer.transform],
                                   [NSValue valueWithCATransform3D:transform],
                                   nil]];

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
        [scaleAnimation setValues:[NSArray arrayWithObjects:
                                   [NSValue valueWithCATransform3D:CATransform3DIdentity],
                                   [NSValue valueWithCATransform3D:transform],
                                   nil]];

        // set the duration of the animation
        [scaleAnimation setDuration: .3];

        // animate your label layer = rock and roll!
        [[self.startDateLabel layer] addAnimation:scaleAnimation forKey:@"scaleText"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"startDate"]) {
		NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];

		[self updateStartLabel:date];
	} else if ([keyPath isEqualToString:@"nowDate"]) {
		NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];

		[self updateNowLabel:date];
	} else if ([keyPath isEqualToString:@"isTransforming"]) {
        EventTimerTransformingEnum isTransforming = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (isTransforming == EventTimerTransformingStartHandStart) {
            [self animateStartDateIsTransforming:YES];
            [self animateTimeRunningIsTransforming:YES];
        } else if (isTransforming == EventTimerTransformingStartHandStop) {
            [self animateStartDateIsTransforming:NO];
            [self animateTimeRunningIsTransforming:NO];
        }
    }
}

@end