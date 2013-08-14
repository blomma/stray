// 
//  CAAnimation+Blocks.h
//  stray
//  
//  Created by Mikael Hultgren on 2013-07-22.
//  Copyright 2013 Artsoftheinsane. All rights reserved.
// 

@interface CAAnimation (BlocksAddition)

@property (nonatomic, copy) void (^completion) (BOOL finished);
@property (nonatomic, copy) void (^start) (void);

- (void)setCompletion:(void (^) (BOOL finished))completion; // Forces auto-complete of setCompletion: to add the name 'finished' in the block parameter

@end
