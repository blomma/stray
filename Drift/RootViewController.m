//
//  RootViewController.m
//  Dift
//
//  Created by Mikael Hultgren on 5/6/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "RootViewController.h"

#import "UIPageViewController+UIPageControl.h"
#import <FontAwesomeKit.h>
#import <HMSideMenu.h>
#import "IconView.h"

@interface RootViewController ()

@property (nonatomic) NSArray *dataModel;
@property (nonatomic) HMSideMenu *sideMenu;

@end

@implementation RootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    static dispatch_once_t once;
    dispatch_once(&once, ^{
        self.view.backgroundColor                      = [UIColor colorWithRed:0.941 green:0.933 blue:0.925 alpha:1.000];
        self.pageControl.backgroundColor               = [UIColor colorWithRed:0.941 green:0.933 blue:0.925 alpha:1.000];
        self.pageControl.pageIndicatorTintColor        = [UIColor colorWithWhite:0.267 alpha:0.2];
        self.pageControl.currentPageIndicatorTintColor = [UIColor colorWithWhite:0.267 alpha:0.8];

        UIButton *button = [[UIButton alloc] init];
        [button addTarget:self
                   action:@selector(touchUpInsideInfoButton:forEvent:)
         forControlEvents:UIControlEventTouchUpInside];

        button.titleLabel.font = [FontAwesomeKit fontWithSize:30];
        button.titleLabel.backgroundColor = [UIColor clearColor];
        button.titleLabel.lineBreakMode   = NSLineBreakByTruncatingTail;

        button.backgroundColor = [UIColor clearColor];

        [button setTitleColor:[UIColor colorWithWhite:0.510f alpha:1.000]
                     forState:UIControlStateNormal];
        [button setTitle:FAKIconOkCircle
                forState:UIControlStateNormal];

        button.frame = CGRectMake(self.view.bounds.size.width - 30, self.view.bounds.size.height - 30, 30, 30);

        [self.view addSubview:button];

        __weak typeof(self) weakSelf = self;
        IconView *settingsItem = [[IconView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        settingsItem.backgroundColor = [UIColor clearColor];
        settingsItem.font = [FontAwesomeKit fontWithSize:40];
        settingsItem.text = FAKIconCogs;
        settingsItem.editable = NO;
        [settingsItem setMenuActionWithBlock:^{
            [weakSelf.sideMenu close];
            [weakSelf performSegueWithIdentifier:@"segueToPreferences"
                                          sender:self];
        }];

        IconView *infoItem = [[IconView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        infoItem.backgroundColor = [UIColor clearColor];
        infoItem.font = [FontAwesomeKit fontWithSize:40];
        infoItem.text = FAKIconInfoSign;
        infoItem.editable = NO;
        [infoItem setMenuActionWithBlock:^{
            [weakSelf.sideMenu close];
            [weakSelf performSegueWithIdentifier:@"segueToInfoHintView"
                                          sender:self];
        }];

        self.sideMenu = [[HMSideMenu alloc] initWithItems:@[settingsItem, infoItem]];
        [self.sideMenu setItemSpacing:10.0f];
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

- (void)touchUpInsideInfoButton:(UIButton *)sender forEvent:(UIEvent *)event {
    if (self.sideMenu.isOpen)
        [self.sideMenu close];
    else
        [self.sideMenu open];
}

@end