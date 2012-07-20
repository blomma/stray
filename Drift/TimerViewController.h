//
//  TimerViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimerFaceControl.h"

@interface TimerViewController : UIViewController

@property (weak, nonatomic) IBOutlet TimerFaceControl *timerFaceControl;
@property (weak, nonatomic) IBOutlet UIButton *toggleStartStopButton;
@property (weak, nonatomic) IBOutlet UILabel *startDateLabel;

@property (weak, nonatomic) IBOutlet UILabel *runningTimerHourLabel;
@property (weak, nonatomic) IBOutlet UILabel *runningTimerMinuteLabel;
@property (weak, nonatomic) IBOutlet UILabel *runningTimerSecondLabel;

@property (weak, nonatomic) IBOutlet UILabel *runningTimerHourMinuteDividerLabel;
@property (weak, nonatomic) IBOutlet UILabel *runningTimerMinuteSecondDividerLabel;

- (IBAction)toggleTimer:(id)sender;

@end
