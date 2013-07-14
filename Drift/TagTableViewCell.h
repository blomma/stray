//
//  TagTableViewCell.h
//  Drift
//
//  Created by Mikael Hultgren on 7/28/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TagTableViewCellBackView.h"

@class TagTableViewCell;

@interface TagTableViewCell : UITableViewCell

- (IBAction)touchUpInsideDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event;

@property (nonatomic, copy) void (^didEditHandler)(NSString *name);
@property (nonatomic, copy) void (^didDeleteHandler)();

@property (nonatomic, weak) IBOutlet UILabel *tagName;
@property (nonatomic, weak) IBOutlet UITextField *tagNameTextField;

@property (nonatomic, weak) IBOutlet TagTableViewCellBackView *backView;

@property (nonatomic, weak) IBOutlet UIView *frontView;
@property (nonatomic) NSString *tagTitle;

@property (nonatomic, weak) IBOutlet UIButton *deleteButton;

@property (nonatomic) BOOL marked;

- (void)marked:(BOOL)marked withAnimation:(BOOL)animation;

@end
