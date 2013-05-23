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

@property (nonatomic) id dropboxChangeObserver;

@end

@implementation PreferencesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.dropboxSyncSwitch.on = [DropboxRepository instance].account ? YES : NO;

    __weak typeof(self) weakSelf = self;
    self.dropboxChangeObserver = [[NSNotificationCenter defaultCenter]
                                  addObserverForName:@"changeAccount"
                                              object:[DropboxRepository instance]
                                               queue:nil
                                          usingBlock:^(NSNotification *note) {
        id account = [[note userInfo] objectForKey:@"account"];
        weakSelf.dropboxSyncSwitch.on = account != [NSNull null] ? YES : NO;
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self.dropboxChangeObserver];
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