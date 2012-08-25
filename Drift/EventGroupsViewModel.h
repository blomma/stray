//
//  EventGroupsViewModel.h
//  Drift
//
//  Created by Mikael Hultgren on 8/25/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EventGroups.h"

@interface EventGroupsViewModel : NSObject <UITableViewDataSource>

@property (nonatomic, strong) EventGroups *eventGroups;

@end
