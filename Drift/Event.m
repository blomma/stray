#import "Event.h"

@interface Event ()
@end

@implementation Event

- (void)awakeFromInsert {
    [super awakeFromInsert];

    self.guid = [[NSProcessInfo processInfo] globallyUniqueString];
}

- (void)awakeFromFetch {
    if (!self.guid) {
        self.guid = [[NSProcessInfo processInfo] globallyUniqueString];
    }
}

- (BOOL)isActive {
    return self.stopDate == nil;
}

@end
