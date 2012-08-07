//
//	TUIScrollView+TUIBridgedScrollView.h
//	TwUI
//
//	Created by Justin Spahr-Summers on 17.07.12.
//
//	Portions of this code were taken from Velvet,
//	which is copyright (c) 2012 Bitswift, Inc.
//	See LICENSE.txt for more information.
//

#import "TUIBridgedScrollView.h"
#import "TUIScrollView.h"

/**
 * Implements support for the c <TUIBridgedScrollView> protocol on TUIScrollView.
 */
@interface TUIScrollView (TUIBridgedScrollView) <TUIBridgedScrollView>
@end
