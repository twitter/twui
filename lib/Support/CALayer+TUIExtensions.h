//
//  CALayer+TUIExtensions.h
//
//  Created by Josh Vera on 11/26/11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

/**
 * Additional geometry conversions and geometrical functions for CALayer.
 */
@interface CALayer (TUIExtensions)
/**
 * Converts a rectangle from the receiver's coordinate system to that of a given
 * layer, taking into account any layer clipping between the two.
 *
 * This will traverse the layer hierarchy, finding a common ancestor between the
 * receiver and 'layer' to use as a base for geometry conversion. If any layers
 * along the way (including the receiver, 'layer', and the common ancestor) have
 * masksToBounds set to YES, the rectangle takes into account their clipping
 * paths, such that the final result represents a rectangle that would actually
 * be visible on screen.
 *
 * The receiver and 'layer' must have a common ancestor.
 */
- (CGRect)tui_convertAndClipRect:(CGRect)rect toLayer:(CALayer *)layer;

/**
 * Converts a rectangle from the coordinate system of 'layer' to the
 * receiver's, taking into account any layer clipping between the two.
 *
 * This will call -tui_convertAndClipRect:toLayer:> on 'layer' with the receiver
 * as the argument.
 *
 * The receiver and 'layer' must have a common ancestor.
 */
- (CGRect)tui_convertAndClipRect:(CGRect)rect fromLayer:(CALayer *)layer;
@end
