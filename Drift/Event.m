#import "Event.h"

@interface Event ()
@end

@implementation Event

- (NSComparisonResult)compare:(id)element {
    if ([element stopDate] == nil) {
        return NSOrderedDescending;
    }

    return [[element startDate] compare:[self startDate]];
}

- (BOOL)isActive {
    return self.stopDate == nil;
}

@end