#import "Event.h"

@interface Event ()

@end

@implementation Event

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

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