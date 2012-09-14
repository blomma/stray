#import "_Event.h"

@interface Event : _Event {}

- (NSComparisonResult)compare:(id)element;
- (BOOL)isActive;

@end
