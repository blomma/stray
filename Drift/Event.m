#import "Event.h"

@implementation Event

// Custom logic goes here.
- (NSComparisonResult)compare:(id)element {
	NSComparisonResult res = [[self startDate] compare:[element startDate]];
	return res;
}

@end