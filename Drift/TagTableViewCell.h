//
//  TagTableViewCell.h
//  Drift
//
//  Created by Mikael Hultgren on 7/28/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "InnerShadowLayer.h"

#import "TagTableViewCellBackView.h"

@class TagTableViewCell;

@protocol TagTableViewCellDelegate <NSObject>

- (void)cell:(TagTableViewCell *)cell tappedDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event;
- (void)cell:(TagTableViewCell *)cell didChangeTagName:(NSString *)name;

@end

@interface TagTableViewCell : UITableViewCell

- (IBAction)touchUpInsideDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event;

@property (nonatomic, weak) id<TagTableViewCellDelegate> delegate;

@property (nonatomic, weak) IBOutlet UILabel *name;
@property (nonatomic, weak) IBOutlet UITextField *nameTextField;

@property (nonatomic, weak) IBOutlet TagTableViewCellBackView *backView;
@property (nonatomic) InnerShadowLayer *backViewInnerShadowLayer;

@property (nonatomic, weak) IBOutlet UIView *frontView;

@property (nonatomic, weak) IBOutlet UIButton *deleteButton;

@property (nonatomic) BOOL marked;

- (void)marked:(BOOL)marked withAnimation:(BOOL)animation;

@end
