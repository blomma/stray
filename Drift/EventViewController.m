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

@property (nonatomic) id <MASConstraint> settingsTouchRightConstraint;
@property (nonatomic) UIView *settingsTouch;

@property (weak, nonatomic) IBOutlet UIView *timeContainer;
@property (weak, nonatomic) IBOutlet UIView *tagContainer;

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
	/// settings touch area
	//-------------------------------------
	self.settingsTouch = [[UIView alloc] init];
	self.settingsTouch.backgroundColor = [UIColor clearColor];
	[self.view addSubview:self.settingsTouch];

	[self.settingsTouch mas_makeConstraints: ^(MASConstraintMaker *make) {
	    make.top.equalTo(self.view.mas_top);
	    make.bottom.equalTo(self.view.mas_bottom);
	    make.width.equalTo(self.view.mas_width);
	    self.settingsTouchRightConstraint = make.right.equalTo(self.view.mas_left).offset(20);
	}];

	UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self
	                                                                      action:@selector(pan:)];
	pan.minimumNumberOfTouches = 1;
	pan.maximumNumberOfTouches = 1;
	[self.settingsTouch addGestureRecognizer:pan];

	UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
	swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
	swipeLeft.numberOfTouchesRequired = 1;
	[self.settingsTouch addGestureRecognizer:swipeLeft];

	UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
	swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
	swipeRight.numberOfTouchesRequired = 1;
	[self.settingsTouch addGestureRecognizer:swipeRight];

	//-------------------------------------
	/// time container
	//-------------------------------------
    UIColor *colorOne = [UIColor colorWithRed:0.851f green:0.851f blue:0.835f alpha:0.3f];
	UIColor *colorTwo = [UIColor colorWithRed:0.851f green:0.851f blue:0.835f alpha:1];

	NSArray *colors = @[(id)colorOne.CGColor, (id)colorTwo.CGColor, (id)colorTwo.CGColor, (id)colorOne.CGColor];
	NSArray *locations = @[@0.0, @0.4, @0.6, @1.0];

	CAGradientLayer *barrier = [CAGradientLayer layer];
	barrier.colors     = colors;
	barrier.locations  = locations;
	barrier.startPoint = CGPointMake(0, 0.5);
	barrier.endPoint   = CGPointMake(1.0, 0.5);

	barrier.bounds = CGRectMake(0, 0, self.timeContainer.bounds.size.width, 0.5);
	barrier.position    = CGPointMake(self.timeContainer.layer.position.x, 0);
	barrier.anchorPoint = self.timeContainer.layer.anchorPoint;

	[self.timeContainer.layer addSublayer:barrier];

	//-------------------------------------
	/// tag container
	//-------------------------------------
	barrier = [CAGradientLayer layer];
	barrier.colors     = colors;
	barrier.locations  = locations;
	barrier.startPoint = CGPointMake(0, 0.5);
	barrier.endPoint   = CGPointMake(1.0, 0.5);

	barrier.bounds = CGRectMake(0, 0, self.tagContainer.bounds.size.width, 0.5);
	barrier.position    = CGPointMake(self.tagContainer.layer.position.x, self.tagContainer.bounds.size.height);
	barrier.anchorPoint = self.tagContainer.layer.anchorPoint;

	[self.tagContainer.layer addSublayer:barrier];
}

- (void)swipe:(UISwipeGestureRecognizer *)recognizer {
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
			[self.settingsTouchRightConstraint uninstall];
			[self.settingsTouch mas_makeConstraints: ^(MASConstraintMaker *make) {
			    self.settingsTouchRightConstraint = make.right.equalTo(self.view.mas_right);
			}];
			[self.settingsTouch layoutIfNeeded];

			[self presentViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"]
			                   animated:YES
			                 completion:nil];
		} else if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
			[self.settingsTouchRightConstraint uninstall];
			[self.settingsTouch mas_makeConstraints: ^(MASConstraintMaker *make) {
			    self.settingsTouchRightConstraint = make.right.equalTo(self.view.mas_left).offset(20);
			}];
			[self.settingsTouch layoutIfNeeded];

			[self dismissViewControllerAnimated:YES
			                         completion:nil];
		}
	}
}

- (void)pan:(UIPanGestureRecognizer *)recognizer {
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		CGPoint velocity = [recognizer velocityInView:self.view];
		if (velocity.x > 0) {
			[self.settingsTouchRightConstraint uninstall];
			[self.settingsTouch mas_makeConstraints: ^(MASConstraintMaker *make) {
			    self.settingsTouchRightConstraint = make.right.equalTo(self.view.mas_right);
			}];
			[self.settingsTouch layoutIfNeeded];

			[self presentViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"]
			                   animated:YES
			                 completion:nil];
		} else if (velocity.x < 0) {
			[self.settingsTouchRightConstraint uninstall];
			[self.settingsTouch mas_makeConstraints: ^(MASConstraintMaker *make) {
			    self.settingsTouchRightConstraint = make.right.equalTo(self.view.mas_left).offset(20);
			}];
			[self.settingsTouch layoutIfNeeded];

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
		} else {
			[self.toggleStartStopButton setTitle:@"START"
			                            forState:UIControlStateNormal];
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
	} else {
		[self reset];

		[State instance].selectedEvent           = [Event create];
		[State instance].selectedEvent.startDate = now;

		[self.eventTimerControl startWithEvent:[State instance].selectedEvent];

		[self.toggleStartStopButton setTitle:@"STOP"
		                            forState:UIControlStateNormal];
	}

	[self.tag setTitle:[State instance].selectedEvent.inTag.name
	          forState:UIControlStateNormal];

    CGRect pathFrame = CGRectMake(-CGRectGetMidY(self.toggleStartStopButton.bounds), -CGRectGetMidY(self.toggleStartStopButton.bounds), self.toggleStartStopButton.bounds.size.height, self.toggleStartStopButton.bounds.size.height);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:pathFrame cornerRadius:pathFrame.size.height/2];

    CGPoint shapePosition = [self.view convertPoint:self.toggleStartStopButton.center fromView:self.eventTimerControl];

    CAShapeLayer *circleShape = [CAShapeLayer layer];
    circleShape.path = path.CGPath;
    circleShape.position = shapePosition;
    circleShape.fillColor = [UIColor clearColor].CGColor;
    circleShape.opacity = 0;
    circleShape.strokeColor = self.toggleStartStopButton.titleLabel.textColor.CGColor;
    circleShape.lineWidth = 2;

    [self.view.layer addSublayer:circleShape];

    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(3, 3, 1)];

    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.fromValue = @1;
    alphaAnimation.toValue = @0;

    CAAnimationGroup *animation = [CAAnimationGroup animation];
    animation.animations = @[scaleAnimation, alphaAnimation];
    animation.duration = 0.5f;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [circleShape addAnimation:animation forKey:nil];
}

#pragma mark -
#pragma mark Private methods

- (void)reset {
	[self.toggleStartStopButton setTitle:@"START"
	                            forState:UIControlStateNormal];

	self.eventStartTime.text    = @"--:--";
	self.eventStartDate.text     = @"";

	self.eventTimeHours.text    = @"00";
	self.eventTimeMinutes.text  = @"00";

	self.eventStopTime.text     = @"--:--";
	self.eventStopDate.text      = @"";

	self.eventStartDate.alpha    = 1;
	self.eventStartTime.alpha   = 1;

	self.eventStopDate.alpha     = 1;
	self.eventStopTime.alpha    = 1;

	self.eventTimeHours.alpha   = 1;
	self.eventTimeMinutes.alpha = 1;
}

- (void)updateStartLabelWithDate:(NSDate *)date {
	if (date) {
		static NSUInteger unitFlags  = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
		NSDateComponents *components = [[NSDate calendar] components:unitFlags
		                                                    fromDate:date];

		self.eventStartTime.text  = [NSString stringWithFormat:@"%02d:%02d", components.hour, components.minute];
		self.eventStartDate.text  = [NSString stringWithFormat:@"%02d%@", components.day, [[self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1] uppercaseString]];
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
		self.eventStopDate.text  = [NSString stringWithFormat:@"%02d%@", components.day, [[self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1] uppercaseString]];
	}
}

@end
