//
//	NSScrollView+TUIExtensions.m
//	TwUI
//
//	Created by Justin Spahr-Summers on 17.07.12.
//
//	Portions of this code were taken from Velvet,
//	which is copyright (c) 2012 Bitswift, Inc.
//	See LICENSE.txt for more information.
//

#import "NSScrollView+TUIExtensions.h"
#import "NSClipView+TUIExtensions.h"
#import "NSView+TUIExtensions.h"

@implementation NSScrollView (TUIExtensions)

#pragma mark TUIBridgedView

// implemented on NSView
@dynamic layer;
@dynamic hostView;

#pragma mark TUIBridgedScrollView

- (void)scrollToPoint:(CGPoint)point; {
	[self.contentView scrollToPoint:point];
}

- (void)scrollToIncludeRect:(CGRect)rect; {
	[self.contentView scrollToIncludeRect:rect];
}

@end
