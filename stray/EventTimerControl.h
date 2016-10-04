#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EventTimerTransformingEnum) {
    EventTimerStartDateDidChange,
    EventTimerStopDateDidChange
};

@protocol EventTimerControlDelegate <NSObject>

- (void)startDateDidUpdate:(NSDate *)startDate;
- (void)runningDateDidUpdateFrom:(NSDate *)fromDate to:(NSDate *)toDate;
- (void)stopDateDidUpdate:(NSDate *)stopDate;
- (void)transformingDidUpdate:(EventTimerTransformingEnum)transform with:(NSDate *)date;

@end

IB_DESIGNABLE
@interface EventTimerControl : UIView

@property (weak, nonatomic) id <EventTimerControlDelegate> delegate;

- (void)initWithStartDate:(NSDate *)startDate andStopDate:(NSDate *)stopDate;
- (void)stop;
- (void)reset;

@end
