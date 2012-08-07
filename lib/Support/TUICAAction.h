//
//  TUICAAction.h
//
//  Created by James Lawton on 11/21/11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

/*
 * A CAAction which finds AppKit views contained in Velvet and animates them
 * alongside. We pass through to the default animation to animate the Velvet
 * views.
 */
@interface TUICAAction : NSObject <CAAction>

/*
 * Initializes an action which proxies for the given action, and handles animation
 * of all descendent TUIViewNSViewContainer instances along with the layer being acted upon.
 *
 * This is the designated initializer.
 */
- (id)initWithAction:(id<CAAction>)innerAction;

/*
 * Returns an action initialized with <initWithAction:>.
 */
+ (id)actionWithAction:(id<CAAction>)innerAction;

/*
 * Whether objects of this class add features to actions for the given key.
 */
+ (BOOL)interceptsActionForKey:(NSString *)key;

@end
