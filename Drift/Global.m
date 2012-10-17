//
//  Global.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-10-17.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Global.h"

@implementation Global

#pragma mark -
#pragma mark Lifecycle

- (id)init {
    self = [super init];
    if (self) {
        self.calendar  = [NSCalendar currentCalendar];
    }

    return self;
}

#pragma mark -
#pragma mark Class methods

+ (Global *)instance {
	static Global *sharedGlobal = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedGlobal = [[self alloc] init];
	});

	return sharedGlobal;
}

@end
