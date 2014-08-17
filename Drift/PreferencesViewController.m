//
//  PreferenceViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 2013-05-10.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import "PreferencesViewController.h"

#import "UnwindSegueSlideDown.h"
#import "DropboxRepository.h"
#import <MGBox.h>
#import <MGLine.h>
#import <MGLineStyled.h>
#import <UIColor+MGExpanded.h>
#import <FontAwesomeKit.h>

static void *PreferencesViewControllerContext = &PreferencesViewControllerContext;

@interface PreferencesViewController ()

@property (nonatomic) MGBox *grid;
@property (nonatomic) UISwitch *dropboxSync;
@property (nonatomic) UIButton *dropboxResync;
@property (nonatomic) id dropboxChangeObserver;
@property (nonatomic) id dropboxSyncObserver;
@property (nonatomic) UIActivityIndicatorView *dropboxActivity;
@property (nonatomic) MGLine *dropboxActivityStatus;

@end

@implementation PreferencesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.close.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:30];
    self.close.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.close.titleLabel.backgroundColor = [UIColor clearColor];

    self.close.backgroundColor = [UIColor clearColor];

    UIColor *color = [UIColor colorWithRed:0.318f green:0.318f blue:0.318f alpha:1];
    [self.close setTitleColor:color forState:UIControlStateNormal];
    [self.close setTitleColor:[color colorByAdding:-0.16f alpha:0] forState:UIControlStateHighlighted];

    [self.close setTitle:FAKIconRemoveSign forState:UIControlStateNormal];

    // setup the main scroller (using a grid layout)
    self.scroller.contentLayoutMode = MGLayoutGridStyle;
    self.scroller.bottomPadding = 8;

    self.grid = [MGBox boxWithSize:self.view.bounds.size];
    self.grid.contentLayoutMode = MGLayoutGridStyle;
    [self.scroller.boxes addObject:self.grid];

    /// Dropbox sync
    float width = self.view.bounds.size.width - 20.0f;
    MGBox *box = [MGBox boxWithSize:(CGSize) {width, 180 }];
    box.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.95 alpha:1];
    box.leftMargin = box.topMargin = 10;
    box.borderStyle = MGBorderEtchedAll;
    [box setBorderColors:[box.backgroundColor colorByAdding:-0.16f alpha:-0.5f]];

    self.dropboxSync = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self.dropboxSync addTarget:self
                               action:@selector(onDropboxSyncSwitch:forEvent:)
                     forControlEvents:UIControlEventValueChanged];

    MGLine *header = [MGLine lineWithLeft:[@"DROPBOX SYNC" uppercaseString]
                                    right:self.dropboxSync
                                     size:(CGSize) {width, 40 }];
    header.leftPadding = header.rightPadding = 10;
    header.textShadowColor = [UIColor clearColor];
    header.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:20];
    header.backgroundColor = [box.backgroundColor colorByAdding:-0.16 alpha:-0.5];
    header.borderStyle = MGBorderEtchedBottom;
    header.bottomBorderColor = [header.backgroundColor colorByAdding:0.16 alpha:-0.5];
    [box.boxes addObject:header];

    MGLine *description = [MGLine lineWithMultilineLeft:@"This will enable a juicy sync to dropbox for all of your timers. Every timer you start, update or delete will be personally hand delivered by the dropbox imps to your dropbox folder, each timer lovingly saved as a separate file in a comma separated value (CSV) format."
                                                  right:nil
                                                  width:width
                                              minHeight:40];

    description.leftPadding = description.rightPadding = 20;
    description.topPadding = 10;
    description.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:15];
    description.textColor = [UIColor colorWithWhite:0.510f alpha:1.000];
    [box.boxes addObject:description];

    [self.grid.boxes addObject:box];

    /// Dropbox sync old entries
    box = [MGBox boxWithSize:(CGSize) {width, 160 }];
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

    header = [MGLine lineWithLeft:[@"DROPBOX RESYNC" uppercaseString]
                            right:self.dropboxResync
                             size:(CGSize) {width, 40 }];
    header.leftPadding = header.rightPadding = 10;
    header.textShadowColor = [UIColor clearColor];
    header.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:20];
    header.backgroundColor = [box.backgroundColor colorByAdding:-0.16 alpha:-0.5];
    header.borderStyle = MGBorderEtchedBottom;
    header.bottomBorderColor = [header.backgroundColor colorByAdding:0.16 alpha:-0.5];
    [box.boxes addObject:header];

    description = [MGLine lineWithMultilineLeft:@"Pushing this red button (you know you want to) will resync every timer you have ever created to your dropbox folder. This might come in handy in cases of extreme clumsiness, i.e., accidentally deleting them from your computer."
                                          right:nil
                                          width:width
                                      minHeight:40];

    description.leftPadding = description.rightPadding = 20;
    description.topPadding = 10;
    description.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:15];
    description.textColor = [UIColor colorWithWhite:0.510f alpha:1.000];
    [box.boxes addObject:description];

    [self.grid.boxes addObject:box];

    /// Sync status
    box = [MGBox boxWithSize:(CGSize) {width, 40}];
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
    header.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:20];
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
                                                                               usingBlock:^(NSNotification *note) {
        id account = [[note userInfo] objectForKey:@"account"];
        weakSelf.dropboxSync.on = account != [NSNull null] ? YES : NO;
        weakSelf.dropboxResync.enabled = weakSelf.dropboxSync.on;
    }];

    if ([DropboxRepository instance].isSyncing) {
        weakSelf.dropboxResync.enabled = NO;
        self.dropboxActivityStatus.leftItems = @[[@"Syncing to dropbox" uppercaseString]].copy;
        [self.dropboxActivity startAnimating];
    } else {
        weakSelf.dropboxResync.enabled = YES;
        self.dropboxActivityStatus.leftItems = @[[@"Dropbox is synced" uppercaseString]].copy;
        [self.dropboxActivity stopAnimating];
    }
    [self.dropboxActivityStatus layout];

    [[DropboxRepository instance] addObserver:self
                                   forKeyPath:NSStringFromSelector(@selector(isSyncing))
                                      options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                      context:PreferencesViewControllerContext];
}

- (void)refresh {

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self.dropboxChangeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.dropboxSyncObserver];

    [[DropboxRepository instance] removeObserver:self
                                      forKeyPath:NSStringFromSelector(@selector(isSyncing))];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)onDropboxSyncSwitch:(id)sender forEvent:(UIEvent *)event {
    if ([sender isOn]) {
        [[DropboxRepository instance] link];
    } else {
        [[DropboxRepository instance] unLink];
    }
}

- (IBAction)onDropboxSync:(id)sender forEvent:(UIEvent *)event {
    self.dropboxResync.enabled = NO;
    [[DropboxRepository instance] sync];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (context == PreferencesViewControllerContext) {
        int changeKindKey = [[change objectForKey:NSKeyValueChangeKindKey] intValue];

        if ([keyPath isEqualToString:NSStringFromSelector(@selector(isSyncing))]) {
            if (changeKindKey == NSKeyValueChangeSetting) {
                id newValue = [change objectForKey:NSKeyValueChangeNewKey];

                if ([newValue boolValue]) {
                    self.dropboxResync.enabled = NO;
                    self.dropboxActivityStatus.leftItems = @[[@"Syncing to dropbox" uppercaseString]].copy;
                    [self.dropboxActivity startAnimating];
                } else {
                    self.dropboxResync.enabled = YES;
                    self.dropboxActivityStatus.leftItems = @[[@"Dropbox is synced" uppercaseString]].copy;
                    [self.dropboxActivity stopAnimating];
                }

                [self.dropboxActivityStatus layout];
            }
        }
    }
}

@end