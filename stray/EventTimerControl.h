#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EventTimerTransformingEnum) {
    EventTimerNot,
    EventTimerStartDateDidStart,
    EventTimerStartDateDidStop,
    EventTimerNowDateDidStart,
    EventTimerNowDateDidStop
};

@protocol EventTimerControlDelegate <NSObject>

- (void)nowDateDidUpdate:(NSDate *)nowDate;
- (void)transformingDidUpdate:(EventTimerTransformingEnum)transform withStartDate:(NSDate *)startDate andStopDate:(NSDate *)stopDate;

@end

@interface EventTimerControl : UIControl

@property (weak, nonatomic) id <EventTimerControlDelegate> delegate;

- (void)initWithStartDate:(NSDate *)startDate andStopDate:(NSDate *)stopDate;
- (void)stop;
- (void)reset;

@end
