#import "TransformableTableViewCell.h"

@implementation TransformableTableViewCell

#pragma mark -
#pragma mark Lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    }

    return self;
}

- (void)prepareForReuse {
    if (!CGRectEqualToRect(self.frontView.frame, self.backView.frame)) {
        self.frontView.frame = self.backView.frame;
    }

    [self.backViewInnerShadowLayer removeFromSuperlayer];
    self.backViewInnerShadowLayer = nil;
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
