//
//  TimerViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TimerFaceControl.h"

@interface EventViewController : UIViewController

@property (weak, nonatomic) IBOutlet TimerFaceControl *timerFaceControl;
@property (weak, nonatomic) IBOutlet UIButton *toggleStartStopButton;
@property (weak, nonatomic) IBOutlet UILabel *startDateLabel;

@property (weak, nonatomic) IBOutlet UILabel *runningTimeLabel;

- (IBAction)toggleTimer:(id)sender;

@end
