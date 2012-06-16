//
//  ViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 5/6/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PagerViewController : UIViewController<UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

- (IBAction)changePage:(id)sender;

@end
