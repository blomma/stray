//
//  TimerViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ClockView.h"

@interface TimerViewController : UIViewController

@property (weak, nonatomic) IBOutlet ClockView *clock;

- (IBAction)startTimer:(id)sender;

@end
