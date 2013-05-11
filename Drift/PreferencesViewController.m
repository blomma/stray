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
        [[[UIAlertView alloc]
          initWithTitle:@"linked" message:@"Aleady linked" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
         show];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)linkToDropbox:(id)sender forEvent:(UIEvent *)event {
    [[DBAccountManager sharedManager] linkFromController:self];
}

@end