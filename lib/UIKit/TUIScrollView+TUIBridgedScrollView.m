//
//	TUIScrollView+TUIBridgedScrollView.m
//	TwUI
//
//	Created by Justin Spahr-Summers on 17.07.12.
//
//	Portions of this code were taken from Velvet,
//	which is copyright (c) 2012 Bitswift, Inc.
//	See LICENSE.txt for more information.
//

#import "TUIScrollView+TUIBridgedScrollView.h"
#import "TUIView+TUIBridgedView.h"
#import <objc/runtime.h>

@implementation TUIScrollView (TUIBridgedScrollView)

#pragma mark TUIBridgedView

// implemented by TUIView
@dynamic layer;
@dynamic hostView;

#pragma mark TUIBridgedScrollView

- (void)scrollToPoint:(CGPoint)point; {
	[self setContentOffset:point animated:YES];
}

- (void)scrollToIncludeRect:(CGRect)rect; {
	[self scrollRectToVisible:rect animated:YES];
}

@end
