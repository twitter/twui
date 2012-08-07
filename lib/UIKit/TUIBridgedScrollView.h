//
//  TUIBridgedScrollView.h
//  TwUI
//
//  Created by Justin Spahr-Summers on 17.07.12.
//
//  Portions of this code were taken from Velvet,
//  which is copyright (c) 2012 Bitswift, Inc.
//  See LICENSE.txt for more information.
//

#import <Foundation/Foundation.h>
#import "TUIBridgedView.h"

/**
 * Represents any kind of bridged scroll view.
 */
@protocol TUIBridgedScrollView <TUIBridgedView>
@required

/**
 * @name Scrolling
 */

/**
 * Scrolls the receiver such that the visible rectangle originates at the given
 * point in the receiver's coordinate system. This method should enable any
 * applicable animations.
 *
 * If scrolling to the given point would result in a rectangle extending past
 * the scroll view's content, the behavior is unspecified; however, the
 * resulting visible rectangle should still include the given point.
 */
- (void)scrollToPoint:(CGPoint)point;

/**
 * Scrolls the receiver the minimum distance required to ensure that the given
 * rectangle is made visible. This method should enable any applicable
 * animations.
 *
 * If the given rectangle is already visible in the scroll view, nothing
 * happens. If the rectangle is larger than the size of the scroll view, as much
 * of the rectangle as possible should be made visible; however, it is
 * unspecified which part of the rectangle will be used.
 *
 * This method is named to avoid method signature conflicts with AppKit.
 */
- (void)scrollToIncludeRect:(CGRect)rect;

@end
