//
//  CustomPagerViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 5/6/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "PagerViewController.h"

@interface RootViewController : PagerViewController

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
