#import <UIKit/UIKit.h>
#import "TableViewGestureRecognizer.h"

@class TransformableTableViewCell;

@protocol TableViewCellEditingRowDelegate <NSObject>

- (void)cell:(TransformableTableViewCell *)cell tappedDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event;

@end

@interface TransformableTableViewCell : UITableViewCell

- (IBAction)tappedDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event;

@property (nonatomic) id<TableViewCellEditingRowDelegate> delegate;

@property (nonatomic, assign) CGFloat finishedHeight;
@property (nonatomic) TableViewCellEditingState state;

@property (nonatomic, weak) IBOutlet UILabel *name;

@property (nonatomic, weak) IBOutlet UIView *backView;
@property (nonatomic, weak) IBOutlet UIView *frontView;

@property (nonatomic, weak) IBOutlet UIButton *deleteButton;

@end
