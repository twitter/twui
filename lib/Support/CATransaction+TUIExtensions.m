//
//	CATransaction+TUIExtensions.m
//
//	Created by James Lawton on 11/23/11.
//	Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "CATransaction+TUIExtensions.h"

@implementation CATransaction (TUIExtensions)
+ (void)tui_performWithDisabledActions:(void(^)(void))block {
	if ([self disableActions]) {
		// actions are already disabled
		block();
	} else {
		[self setDisableActions:YES];
		block();
		[self setDisableActions:NO];
	}
}

@end
