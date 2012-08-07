//
//  TUIViewNSView+Private.h
//
//  Created by James Lawton on 23.11.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "TUIViewNSViewContainer.h"

/**
 * Private functionality of TUIViewNSViewContainer that needs to be exposed to other parts
 * of the framework.
 */
@interface TUIViewNSViewContainer ()

/**
 * Whether the receiver is rendering its NSView.
 */
@property (nonatomic, getter = isRenderingContainedView, readonly) BOOL renderingContainedView;

/**
 * Renders the receiver's rootView once and caches into the receiver's layer,
 * supporting an animation on the NSView as part of the TwUI hierarchy.
 *
 * This method can be called multiple times, but each call must eventually be
 * balanced with a call to -stopRenderingContainedView.
 */
- (void)startRenderingContainedView;

/**
 * Balances a previous call to -startRenderingContainedView.
 *
 * If this balances the initial call to -startRenderingContainedView, the
 * receiver stop rendering the rootView in its layer, and restore the normal
 * AppKit rendering path.
 *
 * This method can be called multiple times to match multiple calls to
 * -startRenderingContainedView.
 */
- (void)stopRenderingContainedView;

/**
 * The frame that the receiver's NSView should have at the time of call.
 *
 * This is used by -synchronizeNSViewGeometry to keep the NSView attached to
 * its TwUI view.
 *
 * If the receiver has no host view, the value is undefined.
 */
@property (readonly) CGRect NSViewFrame;

/**
 * This will synchronize the geometry of the receiver's NSView with that of
 * the receiver, ensuring that the NSView is laid out correctly on screen.
 */
- (void)synchronizeNSViewGeometry;

@end
