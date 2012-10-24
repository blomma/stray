#import "TransformableTableViewCell.h"

@implementation TransformableTableViewCell

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    }

    return self;
}

- (void)prepareForReuse {
    self.frontView.frame = self.backView.frame;
    self.selected = NO;
}

- (IBAction)tappedDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event {
    if ([self.delegate respondsToSelector:@selector(cell:tappedDeleteButton:forEvent:)]) {
        [self.delegate cell:self tappedDeleteButton:sender forEvent:event];
    }
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([self.delegate respondsToSelector:@selector(cell:didChangeTagName:)]) {
        [self.delegate cell:self didChangeTagName:[textField.text copy]];
    }
}

@end
