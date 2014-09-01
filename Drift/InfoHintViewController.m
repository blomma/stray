//
//  InfoHintViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-12-12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "InfoHintViewController.h"
#import <UIColor+MGExpanded.h>

@interface InfoHintViewController ()

@property (nonatomic) BOOL pageControlBeingUsed;

@end

@implementation InfoHintViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSArray *infoImages = @[@"Info-Event", @"Info-EventGroups", @"Info-Events", @"Info-Tags"];

    for (NSUInteger i = 0; i < infoImages.count; i++) {
        CGRect frame;
        frame.origin.x = self.scrollView.frame.size.width * i;
        frame.origin.y = 0;
        frame.size     = self.scrollView.frame.size;

        UIImageView *view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[infoImages objectAtIndex:i]]];
        view.frame = frame;

        [self.scrollView addSubview:view];
    }

    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * infoImages.count, self.scrollView.frame.size.height);

    self.pageControl.currentPage   = 0;
    self.pageControl.numberOfPages = (NSInteger)infoImages.count;

    self.closeInfoHintView.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:30];
    self.closeInfoHintView.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.closeInfoHintView.titleLabel.backgroundColor = [UIColor clearColor];

    self.closeInfoHintView.backgroundColor = [UIColor clearColor];

    UIColor *color = [UIColor colorWithRed:0.941f green:0.933f blue:0.925f alpha:1.000];
    [self.closeInfoHintView setTitleColor:color forState:UIControlStateNormal];
    [self.closeInfoHintView setTitleColor:[color colorByAdding:-0.16f alpha:0] forState:UIControlStateHighlighted];

    [self.closeInfoHintView setTitle:@"\uf057" forState:UIControlStateNormal];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    if (self.pageControlBeingUsed) {
        return;
    }

    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSInteger page    = (NSInteger)floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth);
    page += 1;

    if (self.pageControl.currentPage != page) {
        self.pageControl.currentPage = page;
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.pageControlBeingUsed = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.pageControlBeingUsed = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)pageChanged:(id)sender {
    // Update the scroll view to the appropriate page
    CGRect frame;
    frame.origin.x = self.scrollView.frame.size.width * self.pageControl.currentPage;
    frame.origin.y = 0;
    frame.size     = self.scrollView.frame.size;
    [self.scrollView scrollRectToVisible:frame animated:YES];

    // Keep track of when scrolls happen in response to the page control
    // value changing. If we don't do this, a noticeable "flashing" occurs
    // as the the scroll delegate will temporarily switch back the page
    // number.
    self.pageControlBeingUsed = YES;
}

@end
