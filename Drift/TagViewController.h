//
//  TagViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-22.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Event.h"

@interface TagViewController : UICollectionViewController

- (IBAction)createTag:(id)sender;
- (IBAction)dismissView:(id)sender;
- (IBAction)editTags:(id)sender;
- (IBAction)deleteCell:(id)sender forEvent:(UIEvent *)event;

@property (nonatomic) Event *event;

@end
