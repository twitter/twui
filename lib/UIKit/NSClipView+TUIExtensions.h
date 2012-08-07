//
//	NSClipView+TUIExtensions.h
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
 * Implements <TUIBridgedScrollView> for NSClipView.
 */
@interface NSClipView (TUIExtensions) <TUIBridgedScrollView>
@end
