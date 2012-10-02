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

- (NSSet *)addTag:(Tag *)tag;
- (NSSet *)addTags:(NSArray *)tags;

- (NSSet *)removeTag:(Tag *)tag;
- (NSSet *)removeTags:(NSArray *)tags;

- (Tag *)tagAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfTag:(Tag *)tag;

@end
