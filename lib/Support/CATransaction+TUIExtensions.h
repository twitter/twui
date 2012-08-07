//
//  CATransaction+TUIExtensions.h
//
//  Created by James Lawton on 11/23/11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

/**
 * Extends CATransaction with useful block-based features.
 */
@interface CATransaction (TUIExtensions)

/**
 * Executes a block with actions disabled.
 *
 * This will have the effect of suppressing animation.
 */
+ (void)tui_performWithDisabledActions:(void(^)(void))block;

@end
