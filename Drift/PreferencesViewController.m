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
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if ([DBAccountManager sharedManager].linkedAccount) {
        self.dropboxSyncSwitch.on = YES;
    } else {
        self.dropboxSyncSwitch.on = NO;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onDropboxSyncSwitch:(id)sender forEvent:(UIEvent *)event {
    if (self.dropboxSyncSwitch.on) {
        [[DBAccountManager sharedManager] linkFromController:[[[UIApplication sharedApplication] keyWindow] rootViewController]];
    } else {
        [[DBAccountManager sharedManager].linkedAccount unlink];
    }
}

- (IBAction)onDropboxSync:(id)sender forEvent:(UIEvent *)event {
    [[DropboxRepository instance] sync];
}

@end