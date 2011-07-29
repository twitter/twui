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

- (id)accessibilityHitTest:(NSPoint)point
{
	TUIView *h = [self hitTest:point withEvent:nil];
	return h;
}

- (BOOL)accessibilityIsIgnored
{
    return NO;
}
//
//- (id)accessibilityAttributeValue:(NSString *)attribute 
//{
//    if([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
//		return NSAccessibilityGroupRole;
//    } else if([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
//		return NSAccessibilityRoleDescriptionForUIElement(self);
//	} else if([attribute isEqualToString:NSAccessibilityChildrenAttribute]) {
//		return [self.rootView accessibleSubviews];
//	} else {
//		return [super accessibilityAttributeValue:attribute];
//	}
//}

- (NSArray *)accessibilityAttributeNames
{
    static NSArray *attributes = nil;
    if(attributes == nil) {
		attributes = [[NSArray alloc] initWithObjects:NSAccessibilityRoleAttribute, NSAccessibilityRoleDescriptionAttribute, NSAccessibilityFocusedAttribute, NSAccessibilityChildrenAttribute, NSAccessibilityParentAttribute, NSAccessibilityWindowAttribute, NSAccessibilityTopLevelUIElementAttribute, NSAccessibilityPositionAttribute, NSAccessibilitySizeAttribute, nil];
    }
	
    return attributes;
}

- (id)accessibilityAttributeValue:(NSString *)attribute
{
    if([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
		return NSAccessibilityGroupRole;
    } else if([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
		return NSAccessibilityRoleDescriptionForUIElement(self);
    } else if([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
		id focusedElement = [NSApp accessibilityAttributeValue:NSAccessibilityFocusedUIElementAttribute];
		return [NSNumber numberWithBool:[focusedElement isEqual:self]];
    } else if([attribute isEqualToString:NSAccessibilityParentAttribute]) {
		return NSAccessibilityUnignoredAncestor((id) self.superview ? : self.nsView);
    } else if([attribute isEqualToString:NSAccessibilityWindowAttribute]) {
		return [self.superview accessibilityAttributeValue:NSAccessibilityWindowAttribute];
    } else if([attribute isEqualToString:NSAccessibilityTopLevelUIElementAttribute]) {
		return [self.superview accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
    } else if([attribute isEqualToString:NSAccessibilityPositionAttribute]) {
		return [NSValue valueWithPoint:[[(NSView *)self.nsView window] convertBaseToScreen:[self frameInNSView].origin]];
    } else if([attribute isEqualToString:NSAccessibilitySizeAttribute]) {
		return [NSValue valueWithSize:self.bounds.size];
    } else if([attribute isEqualToString:NSAccessibilityChildrenAttribute]) {
		return [self accessibleSubviews];
	} else {
		return nil;
    }
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute
{
    if([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
		return NO; // TODO: should this be settable?
    } else {
		return NO;
    }
}

- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute
{
    if([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
		// TODO: should we set this?
    }
}

- (NSArray *)accessibilityActionNames
{
    return [NSArray array];
}

- (NSString *)accessibilityActionDescription:(NSString *)action
{
    return nil;
}

- (void)accessibilityPerformAction:(NSString *)action
{
	
}

- (id)accessibilityFocusedUIElement
{
    return NSAccessibilityUnignoredAncestor(self);
}

@end
