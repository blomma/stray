//
//  EventViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventViewController.h"

#import "Event.h"
#import "Tag.h"
#import "TagsTableViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "State.h"
#import "NSDate+Utilities.h"
#import "CAAnimation+Blocks.h"

static void *EventViewControllerContext = &EventViewControllerContext;

@interface EventViewController () <SlideUpTransitioningDelegate, DismissProtocol>

@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) Event *selectedEvent;

//@property (nonatomic) SlideUpTransitioning *slideUpTransitioning;

@end

@implementation EventViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.shortStandaloneMonthSymbols = [[NSDateFormatter new] shortStandaloneMonthSymbols];

//    self.slideUpTransitioning = [SlideUpTransitioning new];
//    self.slideUpTransitioning.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.eventTimerControl addObserver:self
                             forKeyPath:NSStringFromSelector(@selector(startDate))
                                options:(NSKeyValueObservingOptionNew)
                                context:EventViewControllerContext];

    [self.eventTimerControl addObserver:self
                             forKeyPath:NSStringFromSelector(@selector(nowDate))
                                options:(NSKeyValueObservingOptionNew)
                                context:EventViewControllerContext];

    [self.eventTimerControl addObserver:self
                             forKeyPath:NSStringFromSelector(@selector(transforming))
                                options:(NSKeyValueObservingOptionNew)
                                context:EventViewControllerContext];

    NSString *guid = [State instance].selectedEventGUID;
    if (guid) {
        self.selectedEvent = [Event MR_findFirstByAttribute:@"guid"
                                             withValue:guid];
    } else {
        self.selectedEvent = nil;
    }

    NSString *name = nil;
    if (self.selectedEvent) {
        [self.eventTimerControl initWithStartDate:self.selectedEvent.startDate
                                      andStopDate:self.selectedEvent.stopDate];

        if (self.selectedEvent.isActive) {
            [self.toggleStartStopButton setTitle:@"STOP"
                                        forState:UIControlStateNormal];
            [self animateStartEvent];
        } else {
            [self.toggleStartStopButton setTitle:@"START"
                                        forState:UIControlStateNormal];
            [self animateStopEvent];
        }

        name = self.selectedEvent.inTag.name;
    } else {
        [State instance].selectedEventGUID = nil;

        [self reset];
        [self.eventTimerControl reset];
    }

    NSAttributedString *attributeString = nil;
    if (name) {
        attributeString = [[NSAttributedString alloc] initWithString:name
                                                          attributes:@{NSFontAttributeName:[UIFont fontWithName:@"Helvetica Neue" size:14]}];
    } else {
        attributeString = [[NSAttributedString alloc] initWithString:@"\uf02b"
                                                          attributes:@{NSFontAttributeName:[UIFont fontWithName:@"FontAwesome" size:20]}];
    }

    [self.tag setAttributedTitle:attributeString
                        forState:UIControlStateNormal];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

//    if (![self.view.window.gestureRecognizers containsObject:self.slideUpTransitioning.gestureRecogniser]) {
//        [self.view.window addGestureRecognizer:self.slideUpTransitioning.gestureRecogniser];
//    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.eventTimerControl paus];

    [self.eventTimerControl removeObserver:self
                                forKeyPath:NSStringFromSelector(@selector(startDate))];
    [self.eventTimerControl removeObserver:self
                                forKeyPath:NSStringFromSelector(@selector(nowDate))];
    [self.eventTimerControl removeObserver:self
                                forKeyPath:NSStringFromSelector(@selector(transforming))];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToTagsFromEvent"]) {
        TagsTableViewController *controller = (TagsTableViewController *)[segue destinationViewController];
        __weak __typeof__(self) _self = self;
        [controller setDidDismissHandler: ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [_self dismissViewControllerAnimated:YES completion:nil];
            });
        }];

        controller.eventGUID = self.selectedEvent.guid;
    } else if ([segue.identifier isEqualToString:@"segueToEventsFromEvent"]) {
        EventsViewController *controller = (EventsViewController *)[segue destinationViewController];
//        controller.transitioningDelegate = self.slideUpTransitioning;
        controller.dismissDelegate = self;
    }
}


#pragma mark -
#pragma mark DismissProtocol

- (void)didDismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark SlideUpTransitioningDelegate

- (void)proceedToNextViewController {
    [self performSegueWithIdentifier:@"segueToEventsFromEvent"
                              sender:self];
}

#pragma mark -
#pragma mark Public methods

- (IBAction)showTags:(id)sender {
    if (self.selectedEvent) {
        [self animateButton:sender];

        [self performSegueWithIdentifier:@"segueToTagsFromEvent"
                                  sender:self];
    }
}

- (IBAction)toggleEventTouchUpInside:(id)sender forEvent:(UIEvent *)event {
    if (self.selectedEvent.isActive) {
        [self.eventTimerControl stop];
        self.selectedEvent.stopDate = self.eventTimerControl.nowDate;

        [self.toggleStartStopButton setTitle:@"START"
                                    forState:UIControlStateNormal];
        [self animateStopEvent];
    } else {
        [self reset];

        self.selectedEvent = [Event MR_createEntity];
        self.selectedEvent.startDate = [NSDate date];

        [State instance].selectedEventGUID = self.selectedEvent.guid;

        [self.eventTimerControl initWithStartDate:self.selectedEvent.startDate
                                      andStopDate:self.selectedEvent.stopDate];

        [self.toggleStartStopButton setTitle:@"STOP"
                                    forState:UIControlStateNormal];
        [self animateStartEvent];

        NSAttributedString *attributeString = [[NSAttributedString alloc] initWithString:@"\uf02b"
                                                                              attributes:@{NSFontAttributeName:[UIFont fontWithName:@"FontAwesome" size:20]}];
        [self.tag setAttributedTitle:attributeString forState:UIControlStateNormal];
    }

    [self animateButton:sender];

    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
}

#pragma mark -
#pragma mark Private methods

- (void)animateButton:(UIButton *)button {
    CGRect       pathFrame = CGRectMake(-CGRectGetMidY(button.bounds), -CGRectGetMidY(button.bounds), button.bounds.size.height, button.bounds.size.height);
    UIBezierPath *path     = [UIBezierPath bezierPathWithRoundedRect:pathFrame cornerRadius:pathFrame.size.height / 2];

    CGPoint shapePosition = [self.view convertPoint:button.center fromView:button.superview];

    CAShapeLayer *circleShape = [CAShapeLayer layer];
    circleShape.path        = path.CGPath;
    circleShape.position    = shapePosition;
    circleShape.fillColor   = [UIColor clearColor].CGColor;
    circleShape.opacity     = 0;
    circleShape.strokeColor = button.titleLabel.textColor.CGColor;
    circleShape.lineWidth   = 2;

    [self.view.layer addSublayer:circleShape];

    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    scaleAnimation.toValue   = [NSValue valueWithCATransform3D:CATransform3DMakeScale(3, 3, 1)];

    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.fromValue = @1;
    alphaAnimation.toValue   = @0;

    CAAnimationGroup *animation = [CAAnimationGroup animation];
    animation.animations     = @[scaleAnimation, alphaAnimation];
    animation.duration       = 0.5f;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [animation setCompletion: ^(BOOL finished) {
        [circleShape removeFromSuperlayer];
    }];

    [circleShape addAnimation:animation forKey:nil];
}

- (void)reset {
    [self.toggleStartStopButton setTitle:@"START"
                                forState:UIControlStateNormal];

    self.eventStartTime.text    = @"";
    self.eventStartDay.text     = @"";
    self.eventStartYear.text    = @"";
    self.eventStartMonth.text   = @"";

    self.eventTimeHours.text    = @"00";
    self.eventTimeMinutes.text  = @"00";

    self.eventStopTime.text     = @"";
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
        static NSUInteger unitFlags  = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
        NSDateComponents *components = [[NSDate calendar] components:unitFlags
                                                            fromDate:date];

        self.eventStartTime.text  = [NSString stringWithFormat:@"%02ld:%02ld", (long)components.hour, (long)components.minute];
        self.eventStartDay.text   = [NSString stringWithFormat:@"%02ld", (long)components.day];
        self.eventStartYear.text  = [NSString stringWithFormat:@"%04ld", (long)components.year];
        self.eventStartMonth.text = [self.shortStandaloneMonthSymbols objectAtIndex:(NSUInteger)(components.month - 1)];
    }
}

- (void)updateEventTimeFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
    if (fromDate && toDate) {
        static NSUInteger unitFlags  = NSCalendarUnitHour | NSCalendarUnitMinute;
        NSDateComponents  *components = [[NSDate calendar] components:unitFlags
                                                             fromDate:fromDate
                                                               toDate:toDate options:0];

        NSInteger hour = ABS(components.hour);
        NSInteger minute = ABS(components.minute);

        NSString *eventTimeHours = [NSString stringWithFormat:@"%02ld", (long)hour];
        if (components.hour < 0 || components.minute < 0) {
            eventTimeHours = [NSString stringWithFormat:@"-%@", eventTimeHours];
        }

        self.eventTimeHours.text   = eventTimeHours;
        self.eventTimeMinutes.text = [NSString stringWithFormat:@"%02ld", (long)minute];
    }
}

- (void)updateStopLabelWithDate:(NSDate *)date {
    if (date) {
        static NSUInteger unitFlags  = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
        NSDateComponents *components = [[NSDate calendar] components:unitFlags
                                                            fromDate:date];

        self.eventStopTime.text  = [NSString stringWithFormat:@"%02ld:%02ld", (long)components.hour, (long)components.minute];
        self.eventStopDay.text   = [NSString stringWithFormat:@"%02ld", (long)components.day];
        self.eventStopYear.text  = [NSString stringWithFormat:@"%04ld", (long)components.year];
        self.eventStopMonth.text = [self.shortStandaloneMonthSymbols objectAtIndex:(NSUInteger)(components.month - 1)];
    }
}

- (void)animateStartEvent {
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.eventStartTime.alpha = 1;
        self.eventStartDay.alpha = 1;
        self.eventStartMonth.alpha = 1;
        self.eventStartYear.alpha = 1;

        self.eventStopTime.alpha = 0.2f;
        self.eventStopDay.alpha = 0.2f;
        self.eventStopMonth.alpha = 1;
        self.eventStopYear.alpha = 1;
    } completion:nil];
}

- (void)animateStopEvent {
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.eventStartTime.alpha = 0.2f;
        self.eventStartDay.alpha = 0.2f;
        self.eventStartMonth.alpha = 1;
        self.eventStartYear.alpha = 1;

        self.eventStopTime.alpha = 1;
        self.eventStopDay.alpha = 1;
        self.eventStopMonth.alpha = 1;
        self.eventStopYear.alpha = 1;
    } completion:nil];
}

- (void)animateEventTransforming:(EventTimerTransformingEnum)eventTimerTransformingEnum {
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:
     ^{
         CGFloat eventStartAlpha = 1, eventStopAlpha = 1, eventTimeAlpha = 1, eventStartMonthYearAlpha = 1, eventStopMonthYearAlpha = 1;
         switch (eventTimerTransformingEnum) {
             case EventTimerStartDateTransformingStart:
                 eventStartAlpha = 1;
                 eventStartMonthYearAlpha = 1;

                 eventStopAlpha = 0.2f;
                 eventStopMonthYearAlpha = 0.2f;

                 eventTimeAlpha = 0.2f;
                 break;
             case EventTimerStartDateTransformingStop:
                 eventStartAlpha = self.selectedEvent.isActive ? 1 : 0.2f;
                 eventStartMonthYearAlpha = 1;

                 eventStopAlpha = self.selectedEvent.isActive ? 0.2f : 1;
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
                 eventStartAlpha = self.selectedEvent.isActive ? 1 : 0.2f;
                 eventStartMonthYearAlpha = 1;

                 eventStopAlpha = self.selectedEvent.isActive ? 0.2f : 1;
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

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (context == EventViewControllerContext) {
        int changeKindKey = [[change objectForKey:NSKeyValueChangeKindKey] intValue];

        if ([keyPath isEqualToString:NSStringFromSelector(@selector(startDate))]) {
            if (changeKindKey == NSKeyValueChangeSetting) {
                id newValue = [change objectForKey:NSKeyValueChangeNewKey];

                NSDate *toDate = self.eventTimerControl.nowDate;
                [self updateStartLabelWithDate:newValue];
                [self updateEventTimeFromDate:newValue toDate:toDate];
            }
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(nowDate))]) {
            if (changeKindKey == NSKeyValueChangeSetting) {
                id newValue = [change objectForKey:NSKeyValueChangeNewKey];

                NSDate *fromDate = self.eventTimerControl.startDate;
                [self updateStopLabelWithDate:newValue];
                [self updateEventTimeFromDate:fromDate toDate:newValue];
            }
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(transforming))]) {
            if (changeKindKey == NSKeyValueChangeSetting) {
                id newValue = [change objectForKey:NSKeyValueChangeNewKey];

                EventTimerTransformingEnum transforming = [newValue integerValue];

                if (transforming != EventTimerNotTransforming) {
                    [self animateEventTransforming:transforming];
                }

                switch (transforming) {
                    case EventTimerNowDateTransformingStart:
                    case EventTimerStartDateTransformingStart:
//                        self.slideUpTransitioning.gestureRecogniser.enabled = NO;

                        break;
                    case EventTimerNowDateTransformingStop:
//                        self.slideUpTransitioning.gestureRecogniser.enabled = YES;

                        self.selectedEvent.stopDate = self.eventTimerControl.nowDate;
                        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];

                        break;
                    case EventTimerStartDateTransformingStop:
//                        self.slideUpTransitioning.gestureRecogniser.enabled = YES;

                        self.selectedEvent.startDate = self.eventTimerControl.startDate;
                        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];

                        break;

                    default:
                        break;
                }
            }
        }
    }
}

@end
