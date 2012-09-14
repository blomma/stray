#import "Event.h"

@interface Event ()

@end

@implementation Event

- (id)init {
	if ((self = [super init])) {
	}

	return self;
}

- (NSComparisonResult)compare:(id)element {
	return [[self startDate] compare:[element startDate]];
}

- (BOOL)isActive {
    return self.stopDate == nil;
}

@end