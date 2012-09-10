//
//  EventViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventTimerControl.h"

@interface EventViewController : UIViewController

@property (weak, nonatomic) IBOutlet EventTimerControl *eventTimerControl;
@property (weak, nonatomic) IBOutlet UIButton *toggleStartStopButton;
@property (weak, nonatomic) IBOutlet UILabel *startDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *runningTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *stopDateLabel;

- (IBAction)toggleEvent:(id)sender;

@end
