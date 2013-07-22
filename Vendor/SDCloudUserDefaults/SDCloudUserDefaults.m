//
//  SDCloudUserDefaults.m
//
//  Created by Stephen Darlington on 01/09/2011.
//  Copyright (c) 2011 Wandle Software Limited. All rights reserved.
//

#import "SDCloudUserDefaults.h"

@implementation SDCloudUserDefaults

+ (NSString *)stringForKey:(NSString *)aKey {
	return [SDCloudUserDefaults objectForKey:aKey];
}

+ (BOOL)boolForKey:(NSString *)aKey {
	return [[SDCloudUserDefaults objectForKey:aKey] boolValue];
}

+ (id)objectForKey:(NSString *)aKey {
	return [[NSUserDefaults standardUserDefaults] objectForKey:aKey];
}

+ (NSInteger)integerForKey:(NSString *)aKey {
	return [[SDCloudUserDefaults objectForKey:aKey] integerValue];
}

+ (void)setString:(NSString *)aString forKey:(NSString *)aKey {
	[SDCloudUserDefaults setObject:aString forKey:aKey];
}

+ (void)setBool:(BOOL)aBool forKey:(NSString *)aKey {
	[SDCloudUserDefaults setObject:[NSNumber numberWithBool:aBool] forKey:aKey];
}

+ (void)setObject:(id)anObject forKey:(NSString *)aKey {
	[[NSUserDefaults standardUserDefaults] setObject:anObject forKey:aKey];
}

+ (void)setInteger:(NSInteger)anInteger forKey:(NSString *)aKey {
	[SDCloudUserDefaults setObject:[NSNumber numberWithInteger:anInteger]
	                        forKey:aKey];
}

+ (void)removeObjectForKey:(NSString *)aKey {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:aKey];
}

+ (void)synchronize {
	[[NSUserDefaults standardUserDefaults] synchronize];
}

@end
