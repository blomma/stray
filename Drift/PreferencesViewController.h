//
//  PreferenceViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 2013-05-10.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PreferencesViewController : UIViewController
- (IBAction)onDropboxSyncSwitch:(id)sender forEvent:(UIEvent *)event;
- (IBAction)onDropboxSync:(id)sender forEvent:(UIEvent *)event;

@property (weak, nonatomic) IBOutlet UISwitch *dropboxSyncSwitch;

@end
