//
//  PreferenceViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 2013-05-10.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MGScrollView.h>

@interface PreferencesViewController : UIViewController

@property (weak, nonatomic) IBOutlet MGScrollView *scroller;
@property (weak, nonatomic) IBOutlet UIButton *close;

@end
