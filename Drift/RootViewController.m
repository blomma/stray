//
//  RootViewController.m
//  Dift
//
//  Created by Mikael Hultgren on 5/6/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "RootViewController.h"

#import "UIPageViewController+UIPageControl.h"
#import "InfoHintViewDelegate.h"

@interface RootViewController ()

@property (nonatomic) NSArray *dataModel;
@property (nonatomic) BOOL isInited;

@end

@implementation RootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    // Do any additional setup after loading the view, typically from a nib.
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

    if (!self.isInited) {
        // Try and set the background of the pagecontroller if one is present
        self.view.backgroundColor                      = [UIColor colorWithRed:0.941 green:0.933 blue:0.925 alpha:1.000];
        self.pageControl.backgroundColor               = [UIColor colorWithRed:0.941 green:0.933 blue:0.925 alpha:1.000];
        self.pageControl.pageIndicatorTintColor        = [UIColor colorWithWhite:0.267 alpha:0.2];
        self.pageControl.currentPageIndicatorTintColor = [UIColor colorWithWhite:0.267 alpha:0.8];

        UIButton *button = [[UIButton alloc] init];
        [button addTarget:self action:@selector(touchUpInsideInfoButton:forEvent:) forControlEvents:UIControlEventTouchUpInside];

        button.titleLabel.font = [UIFont fontWithName:@"Entypo" size:30];

        button.titleLabel.backgroundColor = [UIColor clearColor];
        button.titleLabel.lineBreakMode   = NSLineBreakByTruncatingTail;

        button.backgroundColor = [UIColor clearColor];

        [button setTitleColor:[UIColor colorWithWhite:0.510f alpha:1.000] forState:UIControlStateNormal];
        [button setTitle:@"\u2753" forState:UIControlStateNormal];

        button.frame = CGRectMake(self.view.bounds.size.width - 30, self.view.bounds.size.height - 30, 30, 30);

        [self.view addSubview:button];

        self.isInited = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
#pragma mark UIPageViewControllerDelegate

#pragma mark -
#pragma mark Private methods

- (void)touchUpInsideInfoButton:(UIButton *)sender forEvent:(UIEvent *)event {
    NSArray *views = self.viewControllers;

    UIViewController *viewController = [views objectAtIndex:0];

    if ([viewController conformsToProtocol:@protocol(InfoHintViewDelegate)]) {
        id<InfoHintViewDelegate> p = (id<InfoHintViewDelegate>)viewController;
        [p showInfoHintView:self.view];
    }
}

@end