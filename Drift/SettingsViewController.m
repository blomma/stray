//
//  SettingsViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 2013-05-10.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import "DropboxRepository.h"
#import "SettingsViewController.h"
#import <THObserversAndBinders.h>
#import "SettingsAnimationController.h"

@interface SettingsViewController ()

@property (nonatomic) id dropboxChangeObserver;
@property (nonatomic) id dropboxSyncObserver;
@property (nonatomic) THObserver *dropboxActivityObserver;

@property (weak, nonatomic) IBOutlet UISwitch *dropboxSwitch;
@property (weak, nonatomic) IBOutlet UIButton *dropboxSync;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *dropboxSyncActivity;
@property (weak, nonatomic) IBOutlet UILabel *dropboxSyncStatus;

@end

@implementation SettingsViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		self.modalPresentationStyle = UIModalPresentationCustom;
		self.transitioningDelegate = self;
	}

	return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	//Adds a shadow to sampleView
	CALayer *layer = self.view.layer;
	layer.shadowOffset = CGSizeMake(1, 1);
	layer.shadowColor = [[UIColor blackColor] CGColor];
	layer.shadowRadius = 4.0f;
	layer.shadowOpacity = 0.80f;
	layer.shadowPath = [[UIBezierPath bezierPathWithRect:layer.bounds] CGPath];

	self.dropboxSwitch.on = [DropboxRepository instance].account ? YES : NO;
	self.dropboxSync.enabled = [DropboxRepository instance].account ? YES : NO;

	__weak typeof(self) weakSelf = self;

	self.dropboxChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"changeAccount"
	                                                                               object:[DropboxRepository instance] queue:nil
	                                                                           usingBlock: ^(NSNotification *note) {
                                                                                   id account = [[note userInfo] objectForKey:@"account"];
                                                                                   weakSelf.dropboxSwitch.on = account != [NSNull null] ? YES : NO;
                                                                                   weakSelf.dropboxSync.enabled = account != [NSNull null] ? YES : NO;
                                                                               }];

	if ([DropboxRepository instance].isSyncing) {
		weakSelf.dropboxSync.enabled = NO;
		self.dropboxSyncStatus.text = @"Syncing";
		[self.dropboxSyncActivity startAnimating];
	} else {
		weakSelf.dropboxSync.enabled = YES;
		self.dropboxSyncStatus.text = @"Synced";
		[self.dropboxSyncActivity stopAnimating];
	}

	self.dropboxActivityObserver = [THObserver observerForObject:[DropboxRepository instance]
	                                                     keyPath:@"isSyncing"
	                                              oldAndNewBlock: ^(id oldValue, id newValue) {
                                                      if ([newValue boolValue] == [oldValue boolValue])
                                                          return;

                                                      if ([newValue boolValue]) {
                                                          weakSelf.dropboxSync.enabled = NO;
                                                          self.dropboxSyncStatus.text = @"Syncing";
                                                          [weakSelf.dropboxSyncActivity startAnimating];
                                                      } else {
                                                          weakSelf.dropboxSync.enabled = YES;
                                                          self.dropboxSyncStatus.text = @"Synced";
                                                          [weakSelf.dropboxSyncActivity stopAnimating];
                                                      }
                                                  }];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[[NSNotificationCenter defaultCenter] removeObserver:self.dropboxChangeObserver];
	[[NSNotificationCenter defaultCenter] removeObserver:self.dropboxSyncObserver];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (IBAction)onDropboxSwitch:(id)sender forEvent:(UIEvent *)event {
	if ([sender isOn])
		[[DropboxRepository instance] linkFromController:self];
	else
		[[DropboxRepository instance] unLink];
}

- (IBAction)onDropboxSync:(id)sender forEvent:(UIEvent *)event {
	self.dropboxSync.enabled = NO;
	[[DropboxRepository instance] sync];
}

#pragma mark -
#pragma mark UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning> )animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
	return [[SettingsAnimationController alloc] init];
}

- (id <UIViewControllerAnimatedTransitioning> )animationControllerForDismissedController:(UIViewController *)dismissed {
	SettingsAnimationController *controller = [[SettingsAnimationController alloc] init];
	controller.isDismissed = YES;

	return controller;
}

@end
