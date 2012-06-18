//
//  TimerViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimerView.h"

@interface TimerViewController : UIViewController

@property (weak, nonatomic) IBOutlet TimerView *timerView;
@property (weak, nonatomic) IBOutlet UIButton *toggleStartStopButton;

- (IBAction)toggleTimer:(id)sender;

@end
