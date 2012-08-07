//
//  TUIView+TUIBridgedView.h
//  TwUI
//
//  Created by Justin Spahr-Summers on 17.07.12.
//
//  Portions of this code were taken from Velvet,
//  which is copyright (c) 2012 Bitswift, Inc.
//  See LICENSE.txt for more information.
//

#import "TUIView.h"
#import "TUIBridgedView.h"

/**
 * Implements support for the <TUIBridgedView> protocol in TUIView.
 */
@interface TUIView (TUIBridgedView) <TUIBridgedView>
- (id<TUIBridgedView>)descendantViewAtPoint:(NSPoint)point;
@end
