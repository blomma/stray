//
//  EventViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventTimerControl.h"

#import "TagsTableViewController.h"
#import "EventsGroupedByStartDateViewController.h"
#import "TagButton.h"
#import "InfoHintViewDelegate.h"

@interface EventViewController : UIViewController <InfoHintViewDelegate, TagsTableViewControllerDelegate, EventsGroupedByStartDateViewControllerDelegate>

@property (nonatomic, weak) IBOutlet EventTimerControl *eventTimerControl;
@property (nonatomic, weak) IBOutlet UIButton *toggleStartStopButton;

@property (nonatomic, weak) IBOutlet UILabel *eventStartTime;
@property (nonatomic, weak) IBOutlet UILabel *eventStartDay;
@property (nonatomic, weak) IBOutlet UILabel *eventStartMonth;
@property (nonatomic, weak) IBOutlet UILabel *eventStartYear;

@property (nonatomic, weak) IBOutlet UILabel *eventTimeHours;
@property (nonatomic, weak) IBOutlet UILabel *eventTimeMinutes;

@property (nonatomic, weak) IBOutlet UILabel *eventStopTime;
@property (nonatomic, weak) IBOutlet UILabel *eventStopDay;
@property (nonatomic, weak) IBOutlet UILabel *eventStopMonth;
@property (nonatomic, weak) IBOutlet UILabel *eventStopYear;

@property (nonatomic, weak) IBOutlet TagButton *tag;

- (IBAction)showTags:(id)sender;
- (IBAction)toggleEventTouchUpInside:(id)sender forEvent:(UIEvent *)event;

@end