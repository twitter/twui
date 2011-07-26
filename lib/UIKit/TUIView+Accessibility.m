//
//  TUIView+Accessibility.m
//  TwUI
//
//  Created by Josh Abernathy on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TUIView+Accessibility.h"


@implementation TUIView (Accessibility)

- (BOOL)isAccessibilityElement
{
    return isAccessibilityElement;
}

- (void)setIsAccessibilityElement:(BOOL)isElement
{
	isAccessibilityElement = isElement;
}

- (NSString *)accessibilityLabel
{
    return accessibilityLabel;
}

- (void)setAccessibilityLabel:(NSString *)label
{
	if(label == accessibilityLabel) return;
	
	[accessibilityLabel release];
	accessibilityLabel = [label copy];
}

- (NSString *)accessibilityHint
{
    return accessibilityHint;
}

- (void)setAccessibilityHint:(NSString *)hint
{
	if(hint == accessibilityHint) return;
	
	[accessibilityHint release];
	accessibilityHint = [hint copy];
}

- (NSString *)accessibilityValue
{
    return accessibilityValue;
}

- (void)setAccessibilityValue:(NSString *)value
{
	if(value == accessibilityValue) return;
	
	[accessibilityValue release];
	accessibilityValue = [value copy];
}

- (TUIAccessibilityTraits)accessibilityTraits
{
    return accessibilityTraits;
}

- (void)setAccessibilityTraits:(TUIAccessibilityTraits)traits
{
	accessibilityTraits = traits;
}

- (CGRect)accessibilityFrame
{
    return accessibilityFrame;
}

- (void)setAccessibilityFrame:(CGRect)frame
{
	accessibilityFrame = frame;
}

- (NSArray *)accessibleSubviews
{
	NSMutableArray *accessibleSubviews = [NSMutableArray array];
	for(TUIView *view in self.subviews) {
//		if([view isAccessibilityElement]) {
			[accessibleSubviews addObject:view];
//		}
	}
	
	return [[accessibleSubviews copy] autorelease];
}


#pragma mark NSAccessibility

- (id)accessibilityAttributeValue:(NSString *)attribute
{
    if([attribute isEqualToString:NSAccessibilityParentAttribute]) {
		return self.superview ? : self.nsView;
    } else if([attribute isEqualToString:NSAccessibilityWindowAttribute]) {
		return [self.superview ? : self.nsView accessibilityAttributeValue:NSAccessibilityWindowAttribute];
    } else if([attribute isEqualToString:NSAccessibilityTopLevelUIElementAttribute]) {
		return [self.superview ? : self.nsView accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
    }  else if([attribute isEqualToString:NSAccessibilityPositionAttribute]) {
		return [NSValue valueWithPoint:[self convertPoint:self.bounds.origin toView:nil]];
    } else if([attribute isEqualToString:NSAccessibilitySizeAttribute]) {
		return [NSValue valueWithSize:[self convertRect:self.bounds toView:nil].size];
    } else {
		return [super accessibilityAttributeValue:attribute];
	}
}

- (id)accessibilityHitTest:(NSPoint)point
{
	TUIView *h = [self hitTest:point withEvent:nil];
	return h;
}

@end
