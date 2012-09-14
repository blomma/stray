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

#pragma mark -
#pragma mark Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
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
    [self.storyboard instantiateViewControllerWithIdentifier:@"EventGroupsTableViewController"]
    ];

    self.dataSource = self;

    [self setViewControllers:@[[self.dataModel objectAtIndex:0]]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:NO
                  completion:nil];
}

- (void)didReceiveMemoryWarning
{
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

@end
