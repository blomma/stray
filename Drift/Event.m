#import "Event.h"

@interface Event ()
@end

@implementation Event

- (BOOL)isActive {
    return self.stopDate == nil;
}

@end