//
//  EventViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventTimerControl.h"
#import "TagButton.h"

@interface EventViewController : UIViewController

@property (nonatomic, weak) IBOutlet EventTimerControl *eventTimerControl;
@property (nonatomic, weak) IBOutlet UIButton *toggleStartStopButton;

@property (nonatomic, weak) IBOutlet UILabel *eventStartTime;
@property (nonatomic, weak) IBOutlet UILabel *eventStartDate;

@property (nonatomic, weak) IBOutlet UILabel *eventTimeHours;
@property (nonatomic, weak) IBOutlet UILabel *eventTimeMinutes;

@property (nonatomic, weak) IBOutlet UILabel *eventStopTime;
@property (nonatomic, weak) IBOutlet UILabel *eventStopDate;

@property (nonatomic, weak) IBOutlet TagButton *tag;

- (IBAction)showTags:(id)sender;
- (IBAction)toggleEventTouchUpInside:(id)sender forEvent:(UIEvent *)event;
- (IBAction)unwindFromSegue:(UIStoryboardSegue *)segue;

@end
