//
//  TagButton.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-11-21.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TagButton.h"
#import <FontAwesomeKit.h>

@interface TagButton ()

@end

@implementation TagButton

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
	}

	return self;
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state {
	if (title) {
		self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
		title = [title uppercaseString];
	} else {
		self.titleLabel.font = [FontAwesomeKit fontWithSize:15];
		title = FAKIconTag;
	}

	[super setTitle:title forState:state];
}

@end
