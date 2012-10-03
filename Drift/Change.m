//
//  Change.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-29.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Change.h"

NSString *const ChangeInsert = @"ChangeInsert";
NSString *const ChangeDelete = @"ChangeDelete";
NSString *const ChangeUpdate = @"ChangeUpdate";

@implementation Change

- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }

    if (!object || ![object isKindOfClass:[self class]]) {
        return NO;
    }

    return [self isEqualToChange:object];
}

- (BOOL)isEqualToChange:(Change *)change {
    return self.index == change.index
    && [self.type isEqualToString:change.type]
    && [self.object isEqual:change.object];
}

- (NSUInteger)hash {
    return self.index ^ [self.type hash] ^ [self.object hash];
}

-(NSString *) description {
    return [NSString stringWithFormat:@"\nindex: %d\ntype: %@\nobject: %@\n",
            self.index, self.type, self.object];
}

@end
