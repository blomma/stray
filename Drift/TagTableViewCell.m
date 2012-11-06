#import "TagTableViewCell.h"

@interface TagTableViewCell ()

@property (nonatomic) CALayer *underLine;
@property (nonatomic) CALayer *selectLayer;

@end

@implementation TagTableViewCell

-(void)drawRect:(CGRect)rect {
    CAShapeLayer *dashLayer = [CAShapeLayer layer];
    dashLayer.frame = CGRectMake(self.nameTextField.frame.origin.x - 10, self.nameTextField.frame.origin.y + 33, self.nameTextField.frame.size.width + 20, 2);
    dashLayer.fillColor = [UIColor clearColor].CGColor;
    dashLayer.strokeColor = [UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:0.5f].CGColor;
    dashLayer.lineWidth = 2.0f;
    dashLayer.lineJoin = kCALineJoinRound;
    dashLayer.lineDashPattern = @[@10, @5];

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0, 0);
    CGPathAddLineToPoint(path, NULL, self.nameTextField.frame.size.width + 20, 0);

    [dashLayer setPath:path];
    CGPathRelease(path);
    
    [self.backView.layer insertSublayer:dashLayer below:self.nameTextField.layer];
}

- (void)prepareForReuse {
    [self marked:NO withAnimation:NO];

    if (self.selectLayer) {
        self.selectLayer.backgroundColor = [UIColor clearColor].CGColor;
    }
}

- (IBAction)touchUpInsideDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event {
    if ([self.delegate respondsToSelector:@selector(cell:tappedDeleteButton:forEvent:)]) {
        [self.delegate cell:self tappedDeleteButton:sender forEvent:event];
    }
}

- (void)marked:(BOOL)marked withAnimation:(BOOL)animation {
    if (self.marked == marked) {
        return;
    }

    self.marked = marked;

    if (!self.selectLayer) {
        self.selectLayer = [CALayer layer];
        self.selectLayer.frame = CGRectMake(self.layer.bounds.size.width - 10, 0, 10, self.layer.bounds.size.height);
        self.selectLayer.backgroundColor = [UIColor clearColor].CGColor;
        [self.frontView.layer addSublayer:self.selectLayer];
    }

    UIColor *backgroundColor = marked ? [UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:1] : [UIColor clearColor];

    if (animation) {
        CABasicAnimation *backgroundAnimation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
        backgroundAnimation.fromValue = (id)self.selectLayer.backgroundColor;
        backgroundAnimation.toValue = (id)backgroundColor.CGColor;
        backgroundAnimation.duration = 0.4;
        [self.selectLayer addAnimation:backgroundAnimation forKey:@"backgroundColor"];
    }

    self.selectLayer.backgroundColor = backgroundColor.CGColor;
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
