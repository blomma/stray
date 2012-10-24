#import <UIKit/UIKit.h>
#import "TransformableTableViewGestureRecognizer.h"
@class TransformableTableViewCell;

@protocol TableViewCellEditingRowDelegate <NSObject>

- (void)cell:(TransformableTableViewCell *)cell tappedDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event;
- (void)cell:(TransformableTableViewCell *)cell didChangeTagName:(NSString *)name;

@end

@interface TransformableTableViewCell : UITableViewCell

- (IBAction)tappedDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event;

@property (nonatomic, weak) id<TableViewCellEditingRowDelegate> delegate;

@property (nonatomic, weak) IBOutlet UILabel *name;
@property (nonatomic, weak) IBOutlet UITextField *textFieldName;

@property (nonatomic, weak) IBOutlet UIView *backView;
@property (nonatomic, weak) IBOutlet UIView *frontView;

@property (nonatomic, weak) IBOutlet UIButton *deleteButton;

@end
