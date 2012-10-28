//
//  Tags.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-30.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tag.h"

@interface Tags : NSObject

@property (nonatomic) NSUInteger count;

- (id)init;
- (id)initWithTags:(NSArray *)tags;

- (void)addObjectsFromArray:(NSArray *)objects;
- (void)removeObjectsInArray:(NSArray *)objects;

- (NSSet *)insertObject:(id)object atIndex:(NSUInteger)index;
- (NSSet *)removeObjectAtIndex:(NSUInteger)index;
- (NSSet *)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object;
- (NSSet *)moveObjectAtIndex:(NSUInteger)atIndex toIndex:(NSUInteger)toIndex;

- (id)objectAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfObject:(id)object;

@end
