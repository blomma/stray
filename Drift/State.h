//
//  State.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-11-15.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Event.h"

@interface State : NSObject

@property (nonatomic, weak) Event *activeEvent;
@property (nonatomic) NSMutableSet *eventGroupsFilter;
@property (nonatomic) NSMutableSet *eventsFilter;

- (void)persistState;

@end
