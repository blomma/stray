//
//  DataManager.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-29.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Tag.h"
#import "State.h"
#import "Event.h"

@interface DataRepository : NSObject

+ (DataRepository *)instance;

- (void)populateRandomData;

@end
