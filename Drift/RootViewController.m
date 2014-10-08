//
//  RootViewController.m
//  Dift
//
//  Created by Mikael Hultgren on 5/6/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "RootViewController.h"

@interface RootViewController ()

@property (nonatomic) NSArray *dataModel;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.dataModel = @[
        [self.storyboard instantiateViewControllerWithIdentifier:@"EventViewController"],
        [self.storyboard instantiateViewControllerWithIdentifier:@"EventStatisticsViewController"]
                     ];

    self.dataSource = self;
    self.delegate   = self;

    [self setViewControllers:@[[self.dataModel objectAtIndex:0]]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:YES
                  completion:nil];

    self.view.backgroundColor = [UIColor colorWithRed:0.941f green:0.933f blue:0.925f alpha:1];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"rootViewDidAppear"
                                                        object:nil];
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

@end