#import "Event.h"

@interface Event ()

@property (nonatomic, readwrite) NSString *GUID;

@end

@implementation Event

- (id)init {
	if ((self = [super init])) {
		self.GUID = [[NSProcessInfo processInfo] globallyUniqueString];
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