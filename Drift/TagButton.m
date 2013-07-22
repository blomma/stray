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

@property (nonatomic) CALayer *titleBackground;

@end

@implementation TagButton

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		self.titleBackground = [CALayer layer];
		self.titleBackground.backgroundColor = [[UIColor colorWithWhite:0.878 alpha:1.000] CGColor];
		self.titleBackground.cornerRadius = 6;
		self.titleBackground.borderColor = [UIColor colorWithWhite:0.267 alpha:0.1f].CGColor;
		self.titleBackground.borderWidth = 0.5f;

		[self.layer insertSublayer:self.titleBackground below:self.titleLabel.layer];
	}

	return self;
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state {
	NSString *oldTitle = [title copy];

	if (title) {
		self.titleLabel.font = [UIFont fontWithName:@"Futura-Medium" size:12];
		title = [title uppercaseString];
	} else {
		self.titleLabel.font = [FontAwesomeKit fontWithSize:20];
		title = FAKIconTag;
	}

	[super setTitle:title forState:state];

	[self renderBackgroundForTitle:oldTitle];
}

#pragma mark -
#pragma mark Private methods

- (void)renderBackgroundForTitle:(NSString *)title {
	CGRect frame = self.titleLabel.frame;

	frame.origin.x -= 6;
	frame.size.width += 12;

	frame.origin.y =  title ? 6 : 5;
	frame.size.height = self.layer.frame.size.height - (title ? 14 : 9);

	self.titleBackground.frame = frame;
}

@end
