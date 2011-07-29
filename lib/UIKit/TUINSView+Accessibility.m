//
//  TUINSView+Accessibility.m
//  TwUI
//
//  Created by Josh Abernathy on 7/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TUINSView+Accessibility.h"
#import "TUIView+Accessibility.h"


@implementation TUINSView (Accessibility)

- (id)accessibilityHitTest:(NSPoint)point
{
	NSPoint windowPoint = [[self window] convertScreenToBase:point];
	NSPoint localPoint = [self convertPoint:windowPoint fromView:nil];
	return [rootView accessibilityHitTest:localPoint];
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
		return NSAccessibilityUnignoredAncestor(self.superview);
    } else if([attribute isEqualToString:NSAccessibilityWindowAttribute]) {
		return [self.superview accessibilityAttributeValue:NSAccessibilityWindowAttribute];
    } else if([attribute isEqualToString:NSAccessibilityTopLevelUIElementAttribute]) {
		return [self.superview accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
    } else if([attribute isEqualToString:NSAccessibilityPositionAttribute]) {
		return [NSValue valueWithPoint:[[self window] convertBaseToScreen:[self convertPoint:self.bounds.origin toView:nil]]];
    } else if([attribute isEqualToString:NSAccessibilitySizeAttribute]) {
		return [NSValue valueWithSize:self.bounds.size];
    } else if([attribute isEqualToString:NSAccessibilityChildrenAttribute]) {
		return [NSArray arrayWithObject:self.rootView];
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
