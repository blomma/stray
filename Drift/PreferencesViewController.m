//
//  PreferenceViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 2013-05-10.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import "PreferencesViewController.h"

#import "UnwindSegueSlideDown.h"
#import <Dropbox/Dropbox.h>
#import "DropboxRepository.h"

@interface PreferencesViewController ()

@end

@implementation PreferencesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    if ([DropboxRepository instance].account) {
        self.dropboxSyncSwitch.on = YES;
    } else {
        self.dropboxSyncSwitch.on = NO;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)onDropboxSyncSwitch:(id)sender forEvent:(UIEvent *)event {
    if (self.dropboxSyncSwitch.on) {
        [[DropboxRepository instance] link];
    } else {
        [[DropboxRepository instance] unLink];
    }
}

- (IBAction)onDropboxSync:(id)sender forEvent:(UIEvent *)event {
    [[DropboxRepository instance] sync];
}

@end