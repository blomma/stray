//
//  EventGroupViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 9/2/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventGroup.h"
#import "EventTimerControl.h"

@interface EventGroupViewController : UIViewController <UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *eventGroupTableView;
@property (weak, nonatomic) IBOutlet EventTimerControl *eventTimerControl;
@property (weak, nonatomic) IBOutlet UIButton *close;

@property (nonatomic) EventGroup *eventGroup;

- (IBAction)closeModal:(id)sender;

@end
