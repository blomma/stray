//
//  TagFilterButton.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-10-14.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Tag.h"

@interface TagFilterButton : UIButton

@property (nonatomic) NSString *tagGuid;
@property (nonatomic) UIFont *titleFont UI_APPEARANCE_SELECTOR;
@property (nonatomic) UIColor *titleBackgroundColor UI_APPEARANCE_SELECTOR;
@property (nonatomic) UIColor *titleColor UI_APPEARANCE_SELECTOR;
@property (nonatomic) UIColor *selectedTitleColor UI_APPEARANCE_SELECTOR;
@property (nonatomic) UIColor *selectedColor UI_APPEARANCE_SELECTOR;

@end
