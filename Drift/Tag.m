#import "Tag.h"

@interface Tag ()

@end

@implementation Tag

- (void)awakeFromInsert {
    [super awakeFromInsert];

    self.guid = [[NSProcessInfo processInfo] globallyUniqueString];
}

@end