//
//  InfoHintViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-12-12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfoHintViewController : UIViewController<UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet UIPageControl *pageControl;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIButton *closeInfoHintView;

- (IBAction)pageChanged:(id)sender;
- (IBAction)dismissInfoHintView:(id)sender;

@end