//
//  NSView+TUIExtensions.h
//  TwUI
//
//  Created by Justin Spahr-Summers on 17.07.12.
//
//  Portions of this code were taken from Velvet,
//  which is copyright (c) 2012 Bitswift, Inc.
//  See LICENSE.txt for more information.
//

#import <AppKit/AppKit.h>
#import "TUIBridgedView.h"

@class TUIViewNSViewContainer;
@protocol TUIHostView;

/**
 * Implements <TUIBridgedView> for NSView.
 */
@interface NSView (TUIExtensions) <TUIBridgedView>

/**
 * The TUIViewNSViewContainer that is hosting this view, or nil if it exists
 * independently of a TwUI hierarchy.
 */
@property (nonatomic, unsafe_unretained) TUIViewNSViewContainer<TUIHostView> *hostView;

@end
