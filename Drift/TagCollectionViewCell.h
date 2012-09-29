//
//  TagCollectionViewCell.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-22.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TagCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UILabel *tagName;
@property (nonatomic, weak) IBOutlet UIButton *deleteTag;

@end
