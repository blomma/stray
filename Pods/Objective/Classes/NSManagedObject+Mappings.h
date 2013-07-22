// 
//  NSManagedObject+Mappings.h
//  Objective
//  
//  Created by Mikael Hultgren on 2013-07-22.
//  Copyright 2013 Mikael Hultgren. All rights reserved.
// 

#import <CoreData/CoreData.h>

@interface NSManagedObject (Mappings)

/// Needs to be overriden in your entity. Not required if you don't have mappings
- (NSDictionary *)mappings;

/// If your web service returns `first_name`, and locally you have `firstName` this method handles mapped keys
- (id)keyForRemoteKey:(NSString *)key;

@end
