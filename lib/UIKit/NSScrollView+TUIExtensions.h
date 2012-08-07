//
//	NSScrollView+TUIExtensions.h
//	TwUI
//
//	Created by Justin Spahr-Summers on 17.07.12.
//
//	Portions of this code were taken from Velvet,
//	which is copyright (c) 2012 Bitswift, Inc.
//	See LICENSE.txt for more information.
//

#import <Cocoa/Cocoa.h>
#import "TUIBridgedScrollView.h"

/**
 * Implements <TUIBridgedScrollView> for NSScrollView.
 *
 * Because the <TUIBridgedScrollView> protocol is already implemented for NSClipView,
 * this category is simply a convenience that invokes the protocol methods
 * against the underlying contentView.
 */
@interface NSScrollView (TUIExtensions) <TUIBridgedScrollView>
@end
