//
//  TagViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-22.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Event.h"

FOUNDATION_EXPORT NSString *const TagDidChangeNotification;

@interface TagViewController : UICollectionViewController

- (IBAction)createTag:(id)sender;
- (IBAction)dismissView:(id)sender;

@property (nonatomic) Event *event;

@end
