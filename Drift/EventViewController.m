//
//  EventViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventViewController.h"
#import "NSDate+Utilities.h"
#import "State.h"
#import "Tag.h"
#import "TagsTableViewController.h"
#import <Objective.h>
#import <THObserversAndBinders.h>

@interface EventViewController ()

@property (nonatomic) NSArray *shortStandaloneMonthSymbols;

// Observer
@property (nonatomic) THObserver *startDateObserver;
@property (nonatomic) THObserver *nowDateObserver;
@property (nonatomic) THObserver *transformingObserver;

@property (nonatomic) id<MASConstraint> preferenceTouchRightConstraint;
@property (nonatomic) UIView *preferenceTouch;

@end

@implementation EventViewController

- (void)viewDidLoad {
	[super viewDidLoad];

    [self setupLayout];

//    [self.view setTranslatesAutoresizingMaskIntoConstraints:NO];
	self.shortStandaloneMonthSymbols = [[NSDateFormatter new] shortStandaloneMonthSymbols];

}

- (void)setupLayout {
    //-------------------------------------
    /// preference touch area
    //-------------------------------------
    self.preferenceTouch = [[UIView alloc] init];
    self.preferenceTouch.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.preferenceTouch];

    [self.preferenceTouch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top);
        make.bottom.equalTo(self.view.mas_bottom);
        make.width.equalTo(self.view.mas_width);
        self.preferenceTouchRightConstraint = make.right.equalTo(self.view.mas_left).offset(100);
    }];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(pan:)];
    pan.minimumNumberOfTouches = 1;
    pan.maximumNumberOfTouches = 1;
    [self.preferenceTouch addGestureRecognizer:pan];

    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    swipeLeft.numberOfTouchesRequired = 1;
    [self.preferenceTouch addGestureRecognizer:swipeLeft];

    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRight.numberOfTouchesRequired = 1;
    [self.preferenceTouch addGestureRecognizer:swipeRight];
}

- (void)swipe:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
            [self.preferenceTouchRightConstraint uninstall];
            [self.preferenceTouch mas_makeConstraints:^(MASConstraintMaker *make) {
                self.preferenceTouchRightConstraint = make.right.equalTo(self.view.mas_right);
            }];
            [self.preferenceTouch layoutIfNeeded];

            [self presentViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"PreferencesViewController"]
                               animated:YES
                             completion:nil];
        } else if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
            [self.preferenceTouchRightConstraint uninstall];
            [self.preferenceTouch mas_makeConstraints:^(MASConstraintMaker *make) {
                self.preferenceTouchRightConstraint = make.right.equalTo(self.view.mas_left).offset(100);
            }];
            [self.preferenceTouch layoutIfNeeded];

            [self dismissViewControllerAnimated:YES
                                     completion:nil];
        }
    }
}

- (void)pan:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint velocity = [recognizer velocityInView:self.view];
        if (velocity.x > 0) {
            [self.preferenceTouchRightConstraint uninstall];
            [self.preferenceTouch mas_makeConstraints:^(MASConstraintMaker *make) {
                self.preferenceTouchRightConstraint = make.right.equalTo(self.view.mas_right);
            }];
            [self.preferenceTouch layoutIfNeeded];

            [self presentViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"PreferencesViewController"]
                               animated:YES
                             completion:nil];
        } else if (velocity.x < 0) {
            [self.preferenceTouchRightConstraint uninstall];
            [self.preferenceTouch mas_makeConstraints:^(MASConstraintMaker *make) {
                self.preferenceTouchRightConstraint = make.right.equalTo(self.view.mas_left).offset(100);
            }];
            [self.preferenceTouch layoutIfNeeded];

            [self dismissViewControllerAnimated:YES
                                     completion:nil];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	__weak typeof(self) weakSelf = self;

	self.startDateObserver = [THObserver observerForObject:self.eventTimerControl keyPath:@"startDate" oldAndNewBlock: ^(id oldValue, id newValue) {
	    [weakSelf updateStartLabelWithDate:newValue];
	    [weakSelf updateEventTimeFromDate:newValue toDate:self.eventTimerControl.nowDate];
	}];

	self.nowDateObserver = [THObserver observerForObject:self.eventTimerControl keyPath:@"nowDate" oldAndNewBlock: ^(id oldValue, id newValue) {
	    [weakSelf updateStopLabelWithDate:newValue];
	    [weakSelf updateEventTimeFromDate:self.eventTimerControl.startDate toDate:newValue];
	}];

	self.transformingObserver = [THObserver observerForObject:self.eventTimerControl keyPath:@"transforming" oldAndNewBlock: ^(id oldValue, id newValue) {
	    EventTimerTransformingEnum transforming = [newValue integerValue];
	    if (transforming != EventTimerNotTransforming)
			[weakSelf animateEventTransforming:transforming];

	    switch (transforming) {
			case EventTimerNowDateTransformingStop:
				[State instance].selectedEvent.stopDate = self.eventTimerControl.nowDate;
				break;

			case EventTimerStartDateTransformingStop:
				[State instance].selectedEvent.startDate = self.eventTimerControl.startDate;
				break;

			default:
				break;
		}
	}];

	if ([State instance].selectedEvent) {
		[self.eventTimerControl startWithEvent:[State instance].selectedEvent];

		if ([[State instance].selectedEvent isActive]) {
			[self.toggleStartStopButton setTitle:@"STOP"
			                            forState:UIControlStateNormal];
			[self animateStartEvent];
		} else {
			[self.toggleStartStopButton setTitle:@"START"
			                            forState:UIControlStateNormal];
			[self animateStopEvent];
		}
	} else {
		[self reset];
		[self.eventTimerControl reset];
	}

	[self.tag setTitle:[[State instance].selectedEvent.inTag.name copy]
	          forState:UIControlStateNormal];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[self.eventTimerControl paus];

	[self.startDateObserver stopObserving];
	[self.nowDateObserver stopObserving];
	[self.transformingObserver stopObserving];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	__weak typeof(self) weakSelf = self;

	[[segue destinationViewController] setDidDismissHandler: ^{
	    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 400000000);
	    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
	        [weakSelf dismissViewControllerAnimated:YES completion:nil];
		});
	}];

	if ([segue.identifier isEqualToString:@"segueToTagsFromEvent"])
		[[segue destinationViewController] setEvent:[State instance].selectedEvent];
}

- (IBAction)unwindFromSegue:(UIStoryboardSegue *)segue {
}

#pragma mark -
#pragma mark Public methods

- (IBAction)showTags:(id)sender {
	if ([State instance].selectedEvent)
		[self performSegueWithIdentifier:@"segueToTagsFromEvent"
		                          sender:self];
}

- (IBAction)toggleEventTouchUpInside:(id)sender forEvent:(UIEvent *)event {
	NSDate *now = [NSDate date];

	if ([[State instance].selectedEvent isActive]) {
		[State instance].selectedEvent.stopDate = now;

		[self.eventTimerControl stop];

		[self.toggleStartStopButton setTitle:@"START"
		                            forState:UIControlStateNormal];
		[self animateStopEvent];
	} else {
		[self reset];

		[State instance].selectedEvent           = [Event create];
		[State instance].selectedEvent.startDate = now;

		[self.eventTimerControl startWithEvent:[State instance].selectedEvent];

		[self.toggleStartStopButton setTitle:@"STOP"
		                            forState:UIControlStateNormal];
		[self animateStartEvent];
	}

	[self.tag setTitle:[State instance].selectedEvent.inTag.name
	          forState:UIControlStateNormal];
}

#pragma mark -
#pragma mark Private methods

- (void)reset {
	[self.toggleStartStopButton setTitle:@"START"
	                            forState:UIControlStateNormal];

	self.eventStartTime.text    = @"--:--";
	self.eventStartDay.text     = @"";
	self.eventStartYear.text    = @"";
	self.eventStartMonth.text   = @"";

	self.eventTimeHours.text    = @"00";
	self.eventTimeMinutes.text  = @"00";

	self.eventStopTime.text     = @"--:--";
	self.eventStopDay.text      = @"";
	self.eventStopYear.text     = @"";
	self.eventStopMonth.text    = @"";

	self.eventStartDay.alpha    = 1;
	self.eventStartMonth.alpha  = 1;
	self.eventStartTime.alpha   = 1;
	self.eventStartYear.alpha   = 1;

	self.eventStopDay.alpha     = 1;
	self.eventStopMonth.alpha   = 1;
	self.eventStopTime.alpha    = 1;
	self.eventStopYear.alpha    = 1;

	self.eventTimeHours.alpha   = 1;
	self.eventTimeMinutes.alpha = 1;
}

- (void)updateStartLabelWithDate:(NSDate *)date {
	if (date) {
		static NSUInteger unitFlags  = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
		NSDateComponents *components = [[NSDate calendar] components:unitFlags
		                                                    fromDate:date];

		self.eventStartTime.text  = [NSString stringWithFormat:@"%02d:%02d", components.hour, components.minute];
		self.eventStartDay.text   = [NSString stringWithFormat:@"%02d", components.day];
		self.eventStartYear.text  = [NSString stringWithFormat:@"%04d", components.year];
		self.eventStartMonth.text = [self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1];
	}
}

- (void)updateEventTimeFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
	if (fromDate && toDate) {
		static NSUInteger unitFlags  = NSHourCalendarUnit | NSMinuteCalendarUnit;

		NSDateComponents *components = [[NSDate calendar] components:unitFlags
		                                                    fromDate:fromDate
		                                                      toDate:toDate options:0];

		self.eventTimeHours.text   = [NSString stringWithFormat:@"%02d", components.hour];
		self.eventTimeMinutes.text = [NSString stringWithFormat:@"%02d", components.minute];
	}
}

- (void)updateStopLabelWithDate:(NSDate *)date {
	if (date) {
		static NSUInteger unitFlags  = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
		NSDateComponents *components = [[NSDate calendar] components:unitFlags
		                                                    fromDate:date];

		self.eventStopTime.text  = [NSString stringWithFormat:@"%02d:%02d", components.hour, components.minute];
		self.eventStopDay.text   = [NSString stringWithFormat:@"%02d", components.day];
		self.eventStopYear.text  = [NSString stringWithFormat:@"%04d", components.year];
		self.eventStopMonth.text = [self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1];
	}
}

- (void)animateStartEvent {
	[UIView animateWithDuration:0.3
	                      delay:0.0
	                    options:UIViewAnimationOptionCurveEaseIn
	                 animations: ^{
                         self.eventStartTime.alpha = 1;
                         self.eventStartDay.alpha = 1;
                         self.eventStartMonth.alpha = 1;
                         self.eventStartYear.alpha = 1;

                         self.eventStopTime.alpha = 0.2;
                         self.eventStopDay.alpha = 0.2;
                         self.eventStopMonth.alpha = 1;
                         self.eventStopYear.alpha = 1;
                     } completion:nil];
}

- (void)animateStopEvent {
	[UIView animateWithDuration:0.3
	                      delay:0.0
	                    options:UIViewAnimationOptionCurveEaseIn
	                 animations: ^{
                         self.eventStartTime.alpha = 0.2;
                         self.eventStartDay.alpha = 0.2;
                         self.eventStartMonth.alpha = 1;
                         self.eventStartYear.alpha = 1;

                         self.eventStopTime.alpha = 1;
                         self.eventStopDay.alpha = 1;
                         self.eventStopMonth.alpha = 1;
                         self.eventStopYear.alpha = 1;
                     } completion:nil];
}

- (void)animateEventTransforming:(EventTimerTransformingEnum)transforming {
	[UIView animateWithDuration:0.3
	                      delay:0.0
	                    options:UIViewAnimationOptionCurveEaseIn
	                 animations: ^{
                         CGFloat eventStartAlpha = 1, eventStopAlpha = 1, eventTimeAlpha = 1, eventStartMonthYearAlpha = 1, eventStopMonthYearAlpha = 1;
                         switch (transforming) {
                             case EventTimerStartDateTransformingStart:
                                 eventStartAlpha = 1;
                                 eventStartMonthYearAlpha = 1;

                                 eventStopAlpha = 0.2f;
                                 eventStopMonthYearAlpha = 0.2f;

                                 eventTimeAlpha = 0.2f;
                                 break;

                             case EventTimerStartDateTransformingStop:
                                 eventStartAlpha = [State instance].selectedEvent.isActive ? 1 : 0.2f;
                                 eventStartMonthYearAlpha = 1;

                                 eventStopAlpha = [State instance].selectedEvent.isActive ? 0.2f : 1;
                                 eventStopMonthYearAlpha = 1;

                                 eventTimeAlpha = 1;
                                 break;

                             case EventTimerNowDateTransformingStart:
                                 eventStartAlpha = 0.2f;
                                 eventStartMonthYearAlpha = 0.2f;

                                 eventStopAlpha = 1;
                                 eventStopMonthYearAlpha = 1;

                                 eventTimeAlpha = 0.2f;

                                 break;

                             case EventTimerNowDateTransformingStop:
                                 eventStartAlpha = [State instance].selectedEvent.isActive ? 1 : 0.2f;
                                 eventStartMonthYearAlpha = 1;

                                 eventStopAlpha = [State instance].selectedEvent.isActive ? 0.2f : 1;
                                 eventStopMonthYearAlpha = 1;

                                 eventTimeAlpha = 1;
                                 break;

                             default:
                                 break;
                         }

                         self.eventStartDay.alpha = eventStartAlpha;
                         self.eventStartMonth.alpha = eventStartMonthYearAlpha;
                         self.eventStartTime.alpha = eventStartAlpha;
                         self.eventStartYear.alpha = eventStartMonthYearAlpha;

                         self.eventStopDay.alpha = eventStopAlpha;
                         self.eventStopMonth.alpha = eventStopMonthYearAlpha;
                         self.eventStopTime.alpha = eventStopAlpha;
                         self.eventStopYear.alpha = eventStopMonthYearAlpha;

                         self.eventTimeHours.alpha = eventTimeAlpha;
                         self.eventTimeMinutes.alpha = eventTimeAlpha;
                     } completion:nil];
}

@end
