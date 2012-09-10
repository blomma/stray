#import "_Event.h"

@interface Event : _Event {}

@property (nonatomic, readonly) NSString *GUID;

- (NSComparisonResult)compare:(id)element;
- (BOOL)isActive;

@end
