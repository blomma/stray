//
//  RootViewController.m
//  Dift
//
//  Created by Mikael Hultgren on 5/6/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "RootViewController.h"

#import <FontAwesomeKit.h>
#import <HMSideMenu.h>
#import "IconView.h"

@interface RootViewController ()

@property (nonatomic) NSArray *dataModel;
@property (nonatomic) HMSideMenu *sideMenu;
@property (nonatomic) UIButton *sideMenuButton;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.dataModel = @[
        [self.storyboard instantiateViewControllerWithIdentifier:@"EventViewController"],
        [self.storyboard instantiateViewControllerWithIdentifier:@"EventsGroupedByDateViewController"]
                     ];

    self.dataSource = self;
    self.delegate   = self;

    [self setViewControllers:@[[self.dataModel objectAtIndex:0]]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:YES
                  completion:nil];

    self.view.backgroundColor = [UIColor colorWithRed:0.941 green:0.933 blue:0.925 alpha:1.000];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    static dispatch_once_t once;
    dispatch_once(&once, ^{

        self.sideMenuButton = [[UIButton alloc] init];
        [self.sideMenuButton addTarget:self
                                action:@selector(touchUpInsideInfoButton:forEvent:)
                      forControlEvents:UIControlEventTouchUpInside];

        self.sideMenuButton.titleLabel.font = [FontAwesomeKit fontWithSize:25];
        self.sideMenuButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.sideMenuButton.titleLabel.backgroundColor = [UIColor clearColor];

        self.sideMenuButton.backgroundColor = [UIColor clearColor];

        [self.sideMenuButton setTitleColor:[UIColor colorWithWhite:0.510f alpha:1.000]
                                  forState:UIControlStateNormal];
        [self.sideMenuButton setTitle:FAKIconChevronSignUp
                             forState:UIControlStateNormal];

        self.sideMenuButton.frame = CGRectMake(self.view.bounds.size.width - 30, self.view.bounds.size.height - 30, 30, 30);

        [self.view addSubview:self.sideMenuButton];

        __weak typeof(self) weakSelf = self;
        IconView *settingsItem = [[IconView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        settingsItem.backgroundColor = [UIColor clearColor];
        settingsItem.font = [FontAwesomeKit fontWithSize:40];
        settingsItem.text = FAKIconCogs;
        settingsItem.editable = NO;
        [settingsItem setMenuActionWithBlock:^{
                [weakSelf toggleSideMenu];
                [weakSelf performSegueWithIdentifier:@"segueToPreferences"
                                              sender:self];
            }];

        IconView *infoItem = [[IconView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        infoItem.backgroundColor = [UIColor clearColor];
        infoItem.font = [FontAwesomeKit fontWithSize:40];
        infoItem.text = FAKIconInfoSign;
        infoItem.editable = NO;
        [infoItem setMenuActionWithBlock:^{
                [weakSelf toggleSideMenu];
                [weakSelf performSegueWithIdentifier:@"segueToInfoHintView"
                                              sender:self];
            }];

        self.sideMenu = [[HMSideMenu alloc] initWithItems:@[settingsItem, infoItem]];
        [self.sideMenu setItemSpacing:18.0f];
        self.sideMenu.menuPosition = HMSideMenuPositionBottom;

        [self.view addSubview:self.sideMenu];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = [self.dataModel indexOfObject:viewController];
    if (index == self.dataModel.count - 1) {
        return nil;
    }

    return [self.dataModel objectAtIndex:index + 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = [self.dataModel indexOfObject:viewController];
    if (index == 0) {
        return nil;
    }

    return [self.dataModel objectAtIndex:index - 1];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return (NSInteger)self.dataModel.count;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    return 0;
}

#pragma mark -
#pragma mark Private methods

- (void)toggleSideMenu {
    if (self.sideMenu.isOpen) {
        [self.sideMenu close];
        [UIView animateWithDuration:0.4f animations:^{
            self.sideMenuButton.transform = CGAffineTransformMakeRotation(0);
        }];
    } else {
        [self.sideMenu open];
        [UIView animateWithDuration:0.4f animations:^{
            self.sideMenuButton.transform = CGAffineTransformMakeRotation(M_PI);
        }];
    }
}

- (void)touchUpInsideInfoButton:(UIButton *)sender forEvent:(UIEvent *)event {
    [self toggleSideMenu];
}

@end