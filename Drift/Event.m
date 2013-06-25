#import "Event.h"

@interface Event ()
@end

@implementation Event

- (void)awakeFromInsert {
    [super awakeFromInsert];

    self.guid = [[NSUUID UUID] UUIDString];
}

- (BOOL)isActive {
    return self.stopDate == nil;
}

@end
