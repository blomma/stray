#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EventTimerTransformingEnum) {
    EventTimerNotTransforming,
    EventTimerStartDateTransformingStart,
    EventTimerStartDateTransformingStop,
    EventTimerNowDateTransformingStart,
    EventTimerNowDateTransformingStop
};

@protocol EventTimerControlDelegate <NSObject>

- (void)startDateDidUpdate:(NSDate *)startDate;
- (void)nowDateDidUpdate:(NSDate *)nowDate;
- (void)transformingDidUpdate:(EventTimerTransformingEnum)transform;

@end

@interface EventTimerControl : UIControl

@property (weak, nonatomic) id <EventTimerControlDelegate> delegate;

@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *nowDate;

@property (nonatomic) EventTimerTransformingEnum transforming;

- (void)initWithStartDate:(NSDate *)startDate andStopDate:(NSDate *)stopDate;
- (void)paus;
- (void)stop;
- (void)reset;

@end
