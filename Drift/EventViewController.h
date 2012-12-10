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
#import "InfoView.h"

@interface EventViewController : UIViewController <InfoView, TagsTableViewControllerDelegate, EventsGroupedByStartDateViewControllerDelegate>

@property (weak, nonatomic) IBOutlet EventTimerControl *eventTimerControl;
@property (weak, nonatomic) IBOutlet UIButton *toggleStartStopButton;

@property (weak, nonatomic) IBOutlet UILabel *eventStartTime;
@property (weak, nonatomic) IBOutlet UILabel *eventStartDay;
@property (weak, nonatomic) IBOutlet UILabel *eventStartMonth;
@property (weak, nonatomic) IBOutlet UILabel *eventStartYear;

@property (weak, nonatomic) IBOutlet UILabel *eventTimeHours;
@property (weak, nonatomic) IBOutlet UILabel *eventTimeMinutes;

@property (weak, nonatomic) IBOutlet UILabel *eventStopTime;
@property (weak, nonatomic) IBOutlet UILabel *eventStopDay;
@property (weak, nonatomic) IBOutlet UILabel *eventStopMonth;
@property (weak, nonatomic) IBOutlet UILabel *eventStopYear;

@property (weak, nonatomic) IBOutlet TagButton *tag;

- (IBAction)toggleEvent:(id)sender;
- (IBAction)showTags:(id)sender;

@end
