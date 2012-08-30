//
//  ViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/6/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "PagerViewController.h"

@interface PagerViewController ()

@property (nonatomic, assign) BOOL pageControlUsed;
@property (nonatomic, assign) NSUInteger page;
@property (nonatomic, assign) BOOL rotating;

- (void)loadScrollViewWithPage:(int)page;

@end

@implementation PagerViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.pageControl.backgroundColor = [UIColor colorWithRed:0.075 green:0.075 blue:0.075 alpha:1];
	self.scrollView.backgroundColor  = [UIColor colorWithRed:0.075 green:0.075 blue:0.075 alpha:1];
}

- (BOOL)automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers {
	return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	UIViewController *viewController = [self.childViewControllers objectAtIndex:(NSUInteger)self.pageControl.currentPage];
	[viewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

	self.rotating = YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	UIViewController *viewController = [self.childViewControllers objectAtIndex:(NSUInteger)self.pageControl.currentPage];
	[viewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];

	self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * [self.childViewControllers count],
	                                         self.scrollView.frame.size.height);

	NSUInteger page = 0;

	for (viewController in self.childViewControllers) {
		CGRect frame = self.scrollView.frame;
		frame.origin.x            = frame.size.width * page;
		frame.origin.y            = 0;

		viewController.view.frame = frame;
		page++;
	}

	CGRect frame = self.scrollView.frame;
	frame.origin.x = frame.size.width * self.page;
	frame.origin.y = 0;

	[self.scrollView scrollRectToVisible:frame animated:NO];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	self.rotating = NO;

	UIViewController *viewController = [self.childViewControllers objectAtIndex:(NSUInteger)self.pageControl.currentPage];
	[viewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	for (NSUInteger i = 0; i < [self.childViewControllers count]; i++) {
		[self loadScrollViewWithPage:(NSInteger)i];
	}

	self.pageControl.currentPage = 0;
	self.page                    = 0;
	[self.pageControl setNumberOfPages:(NSInteger)[self.childViewControllers count]];

	UIViewController *viewController = [self.childViewControllers objectAtIndex:(NSUInteger)self.pageControl.currentPage];
	if (viewController.view.superview != nil) {
		[viewController viewWillAppear:animated];
	}

	self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * [self.childViewControllers count], self.scrollView.frame.size.height);
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	UIViewController *viewController = [self.childViewControllers objectAtIndex:(NSUInteger)self.pageControl.currentPage];
	if (viewController.view.superview != nil)
		[viewController viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	UIViewController *viewController = [self.childViewControllers objectAtIndex:(NSUInteger)self.pageControl.currentPage];
	if (viewController.view.superview != nil)
		[viewController viewWillDisappear:animated];

	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	UIViewController *viewController = [self.childViewControllers objectAtIndex:(NSUInteger)self.pageControl.currentPage];
	if (viewController.view.superview != nil)
		[viewController viewDidDisappear:animated];

	[super viewDidDisappear:animated];
}

- (void)loadScrollViewWithPage:(int)page {
	if (page < 0)
		return;

	if (page >= (NSInteger)[self.childViewControllers count])
		return;

	// replace the placeholder if necessary
	UIViewController *controller = [self.childViewControllers objectAtIndex:(NSUInteger)page];
	if (controller == nil)
		return;

	// add the controller's view to the scroll view
	if (controller.view.superview == nil) {
		CGRect frame = self.scrollView.frame;
		frame.origin.x        = frame.size.width * page;
		frame.origin.y        = 0;

		controller.view.frame = frame;

		[self.scrollView addSubview:controller.view];
	}
}

- (IBAction)changePage:(id)sender {
	int page = ((UIPageControl *)sender).currentPage;

	// update the scroll view to the appropriate page
	CGRect frame = self.scrollView.frame;
	frame.origin.x = frame.size.width * page;
	frame.origin.y = 0;

	UIViewController *oldViewController = [self.childViewControllers objectAtIndex:self.page];
	UIViewController *newViewController = [self.childViewControllers objectAtIndex:(NSUInteger)self.pageControl.currentPage];
	[oldViewController viewWillDisappear:YES];
	[newViewController viewWillAppear:YES];

	[self.scrollView scrollRectToVisible:frame animated:YES];

	// Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above.
	self.pageControlUsed = YES;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	UIViewController *oldViewController = [self.childViewControllers objectAtIndex:self.page];
	UIViewController *newViewController = [self.childViewControllers objectAtIndex:(NSUInteger)self.pageControl.currentPage];

	[oldViewController viewDidDisappear:YES];
	[newViewController viewDidAppear:YES];

	self.page = self.pageControl.currentPage;
}

#pragma mark -
#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)sender {
	// We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
	// which a scroll event generated from the user hitting the page control triggers updates from
	// the delegate method. We use a boolean to disable the delegate logic when the page control is used.
	if (self.pageControlUsed || self.rotating)
		// do nothing - the scroll was initiated from the page control, not the user dragging
		return;

	// Switch the indicator when more than 50% of the previous/next page is visible
	CGFloat pageWidth = self.scrollView.frame.size.width;
	NSInteger page    = (NSInteger)floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth);
	page += 1;

	if (self.pageControl.currentPage != page) {
		UIViewController *oldViewController = [self.childViewControllers objectAtIndex:(NSUInteger)self.pageControl.currentPage];
		UIViewController *newViewController = [self.childViewControllers objectAtIndex:(NSUInteger)page];

		[oldViewController viewWillDisappear:YES];
		[newViewController viewWillAppear:YES];

		self.pageControl.currentPage = page;

		[oldViewController viewDidDisappear:YES];
		[newViewController viewDidAppear:YES];

		self.page = page;
	}
}

// At the begin of scroll dragging, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	self.pageControlUsed = NO;
}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	self.pageControlUsed = NO;
}

@end
