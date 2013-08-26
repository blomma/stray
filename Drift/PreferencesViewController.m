//
//  PreferenceViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 2013-05-10.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import "DropboxRepository.h"
#import "PreferencesViewController.h"
#import <FontAwesomeKit.h>
#import <MGBox.h>
#import <MGLine.h>
#import <MGLineStyled.h>
#import <THObserversAndBinders.h>
#import <UIColor+MGExpanded.h>
#import <MGScrollView.h>
#import "PreferenceAnimationController.h"

@interface PreferencesViewController ()

@property (nonatomic) MGBox *grid;
@property (nonatomic) UISwitch *dropboxSync;
@property (nonatomic) UIButton *dropboxResync;
@property (nonatomic) id dropboxChangeObserver;
@property (nonatomic) id dropboxSyncObserver;
@property (nonatomic) THObserver *dropboxActivityObserver;
@property (nonatomic) UIActivityIndicatorView *dropboxActivity;
@property (nonatomic) MGLine *dropboxActivityStatus;

@end

@implementation PreferencesViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self;
    }

    return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];

    //Adds a shadow to sampleView
    CALayer *layer = self.view.layer;
    layer.shadowOffset = CGSizeMake(1, 1);
    layer.shadowColor = [[UIColor blackColor] CGColor];
    layer.shadowRadius = 4.0f;
    layer.shadowOpacity = 0.80f;
    layer.shadowPath = [[UIBezierPath bezierPathWithRect:layer.bounds] CGPath];

	// setup the main scroller (using a grid layout)
	self.scroller.contentLayoutMode = MGLayoutGridStyle;
	self.scroller.bottomPadding = 8;

	self.grid = [MGBox boxWithSize:self.scroller.bounds.size];
	self.grid.contentLayoutMode = MGLayoutGridStyle;
	[self.scroller.boxes addObject:self.grid];

	/// Dropbox sync
	float width = self.scroller.bounds.size.width - 20.0f;
	MGBox *box = [MGBox boxWithSize:(CGSize) {width, 20 }];
	box.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.95 alpha:1];
	box.leftMargin = box.topMargin = 10;
	box.borderStyle = MGBorderEtchedAll;
	[box setBorderColors:[box.backgroundColor colorByAdding:-0.16f alpha:-0.5f]];

	self.dropboxSync = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
	[self.dropboxSync addTarget:self
	                     action:@selector(onDropboxSyncSwitch:forEvent:)
	           forControlEvents:UIControlEventValueChanged];

	MGLine *header = [MGLine lineWithLeft:@"Dropbox"
	                                right:self.dropboxSync
	                                 size:(CGSize) {width, 40 }];
	header.leftPadding = header.rightPadding = 10;
	header.textShadowColor = [UIColor clearColor];
	header.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
	header.backgroundColor = [box.backgroundColor colorByAdding:-0.16 alpha:-0.5];
	header.borderStyle = MGBorderEtchedBottom;
	header.bottomBorderColor = [header.backgroundColor colorByAdding:0.16 alpha:-0.5];
	[box.boxes addObject:header];

//	MGLine *description = [MGLine lineWithMultilineLeft:@"This will enable a juicy sync to dropbox for all of your timers. Every timer you start, update or delete will be personally hand delivered by the dropbox imps to your dropbox folder, each timer lovingly saved as a separate file in a comma separated value (CSV) format."
//	                                              right:nil
//	                                              width:width
//	                                          minHeight:40];
//
//	description.leftPadding = description.rightPadding = 20;
//	description.topPadding = 10;
//	description.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
//	description.textColor = [UIColor colorWithWhite:0.510f alpha:1.000];
//	[box.boxes addObject:description];

	[self.grid.boxes addObject:box];

	/// Dropbox sync old entries
	box = [MGBox boxWithSize:(CGSize) {width, 20 }];
	box.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.95 alpha:1];
	box.leftMargin = box.topMargin = 10;
	box.borderStyle = MGBorderEtchedAll;
	[box setBorderColors:[box.backgroundColor colorByAdding:-0.16f alpha:-0.5f]];

	self.dropboxResync = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	self.dropboxResync.frame = CGRectMake(0, 0, 30, 30);
	self.dropboxResync.titleLabel.font = [FontAwesomeKit fontWithSize:18];
	self.dropboxResync.titleLabel.textAlignment = NSTextAlignmentCenter;
	[self.dropboxResync setTitle:FAKIconRetweet forState:UIControlStateNormal];
	[self.dropboxResync setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
	[self.dropboxResync setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];

	[self.dropboxResync addTarget:self
	                       action:@selector(onDropboxSync:forEvent:)
	             forControlEvents:UIControlEventTouchUpInside];

	header = [MGLine lineWithLeft:@"Dropbox resync"
	                        right:self.dropboxResync
	                         size:(CGSize) {width, 40 }];
	header.leftPadding = header.rightPadding = 10;
	header.textShadowColor = [UIColor clearColor];
	header.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
	header.backgroundColor = [box.backgroundColor colorByAdding:-0.16 alpha:-0.5];
	header.borderStyle = MGBorderEtchedBottom;
	header.bottomBorderColor = [header.backgroundColor colorByAdding:0.16 alpha:-0.5];
	[box.boxes addObject:header];

//	description = [MGLine lineWithMultilineLeft:@"Pushing this red button (you know you want to) will resync every timer you have ever created to your dropbox folder. This might come in handy in cases of extreme clumsiness, i.e., accidentally deleting them from your computer."
//	                                      right:nil
//	                                      width:width
//	                                  minHeight:40];
//
//	description.leftPadding = description.rightPadding = 20;
//	description.topPadding = 10;
//	description.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
//	description.textColor = [UIColor colorWithWhite:0.510f alpha:1.000];
//	[box.boxes addObject:description];

	[self.grid.boxes addObject:box];

	/// Sync status
	box = [MGBox boxWithSize:(CGSize) {width, 20 }];
	box.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.95 alpha:1];
	box.leftMargin = box.topMargin = 10;
	box.borderStyle = MGBorderEtchedAll;
	[box setBorderColors:[box.backgroundColor colorByAdding:-0.16f alpha:-0.5f]];

	self.dropboxActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];

	self.dropboxActivityStatus = header = [MGLine lineWithLeft:@""
	                                                     right:self.dropboxActivity
	                                                      size:(CGSize) {width, 40 }];
	header.leftPadding = header.rightPadding = 10;
	header.textShadowColor = [UIColor clearColor];
	header.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
	header.backgroundColor = [box.backgroundColor colorByAdding:-0.16 alpha:-0.5];
	header.borderStyle = MGBorderEtchedBottom;
	header.bottomBorderColor = [header.backgroundColor colorByAdding:0.16 alpha:-0.5];
	[box.boxes addObject:header];

	[self.grid.boxes addObject:box];
	[self.grid layoutWithSpeed:0.3 completion:nil];
	[self.scroller layoutWithSpeed:0.3 completion:nil];
	[self.scroller scrollToView:self.grid withMargin:10];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	self.dropboxSync.on = [DropboxRepository instance].account ? YES : NO;
	self.dropboxResync.enabled = self.dropboxSync.on;

	__weak typeof(self) weakSelf = self;

	self.dropboxChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"changeAccount" object:[DropboxRepository instance] queue:nil
	                                                                           usingBlock: ^(NSNotification *note) {
                                                                                   id account = [[note userInfo] objectForKey:@"account"];
                                                                                   weakSelf.dropboxSync.on = account != [NSNull null] ? YES : NO;
                                                                                   weakSelf.dropboxResync.enabled = weakSelf.dropboxSync.on;
                                                                               }];

	if ([DropboxRepository instance].isSyncing) {
		weakSelf.dropboxResync.enabled = NO;
		self.dropboxActivityStatus.leftItems = @[@"Syncing to dropbox"].copy;
		[self.dropboxActivity startAnimating];
	} else {
		weakSelf.dropboxResync.enabled = YES;
		self.dropboxActivityStatus.leftItems = @[@"Dropbox is synced"].copy;
		[self.dropboxActivity stopAnimating];
	}
	[self.dropboxActivityStatus layout];

	self.dropboxActivityObserver = [THObserver observerForObject:[DropboxRepository instance] keyPath:@"isSyncing" oldAndNewBlock: ^(id oldValue, id newValue) {
	    if ([newValue boolValue] == [oldValue boolValue])
			return;

	    if ([newValue boolValue]) {
	        weakSelf.dropboxResync.enabled = NO;
	        weakSelf.dropboxActivityStatus.leftItems = @[@"Syncing to dropbox"].copy;
	        [weakSelf.dropboxActivity startAnimating];
		} else {
	        weakSelf.dropboxResync.enabled = YES;
	        weakSelf.dropboxActivityStatus.leftItems = @[@"Dropbox is synced"].copy;
	        [weakSelf.dropboxActivity stopAnimating];
		}
	    [weakSelf.dropboxActivityStatus layout];
	}];
}

- (void)refresh {
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[[NSNotificationCenter defaultCenter] removeObserver:self.dropboxChangeObserver];
	[[NSNotificationCenter defaultCenter] removeObserver:self.dropboxSyncObserver];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (IBAction)onDropboxSyncSwitch:(id)sender forEvent:(UIEvent *)event {
	if ([sender isOn])
		[[DropboxRepository instance] linkFromController:self];
	else
		[[DropboxRepository instance] unLink];
}

- (IBAction)onDropboxSync:(id)sender forEvent:(UIEvent *)event {
	self.dropboxResync.enabled = NO;
	[[DropboxRepository instance] sync];
}

/// UIViewControllerTransitioningDelegate
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return [[PreferenceAnimationController alloc] init];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    PreferenceAnimationController *controller = [[PreferenceAnimationController alloc] init];
    controller.isDismissed = YES;

    return controller;
}

@end
