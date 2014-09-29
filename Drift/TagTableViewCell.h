//
//  TagTableViewCell.h
//  Drift
//
//  Created by Mikael Hultgren on 7/28/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TagTableViewCellBackView.h"

@class TagTableViewCell;

@protocol TagTableViewCellDelegate <NSObject>

- (void)cell:(TagTableViewCell *)cell tappedDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event;
- (void)cell:(TagTableViewCell *)cell didChangeTagName:(NSString *)name;

@end

@interface TagTableViewCell : UITableViewCell

- (IBAction)touchUpInsideDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event;

@property (nonatomic, weak) id<TagTableViewCellDelegate> delegate;

@property (nonatomic, weak) IBOutlet UILabel *tagName;
@property (nonatomic, weak) IBOutlet UITextField *tagNameTextField;

@property (nonatomic, weak) IBOutlet TagTableViewCellBackView *backView;

@property (nonatomic, weak) IBOutlet UIView *frontView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *trailing;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backViewToEdit;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftSeparator;
@property (weak, nonatomic) IBOutlet UIView *rightSelected;

@property (nonatomic) NSString *tagTitle;

@property (nonatomic, weak) IBOutlet UIButton *deleteButton;

@property (nonatomic) BOOL marked;

- (void)marked:(BOOL)marked withAnimation:(BOOL)animation;

@end
