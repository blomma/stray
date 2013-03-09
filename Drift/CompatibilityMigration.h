//
//  CompatibilityMigration.h
//  Drift
//
//  Created by Mikael Hultgren on 2013-03-09.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CompatibilityMigration : NSObject

+ (CompatibilityMigration *)instance;

- (void)migrate;

@end
