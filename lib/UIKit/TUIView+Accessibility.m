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
	
	accessibilityLabel = [label copy];
}

- (NSString *)accessibilityHint
{
    return accessibilityHint;
}

- (void)setAccessibilityHint:(NSString *)hint
{
	if(hint == accessibilityHint) return;
	
	accessibilityHint = [hint copy];
}

- (NSString *)accessibilityValue
{
    return accessibilityValue;
}

- (void)setAccessibilityValue:(NSString *)value
{
	if(value == accessibilityValue) return;
	
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
	// nothing set so use the view's frame converted to screen coordinates
	if(CGRectEqualToRect(accessibilityFrame, CGRectNull)) {
		CGRect frame = self.frame;
		frame.origin = [[(NSView *) self.nsView window] convertBaseToScreen:[self frameInNSView].origin];
		return frame;
	} else {
		return accessibilityFrame;
	}
}

- (void)setAccessibilityFrame:(CGRect)frame
{
	accessibilityFrame = frame;
}


#pragma mark NSAccessibility

- (id)accessibilityHitTest:(NSPoint)point
{	
	if((self.userInteractionEnabled == NO) || (self.hidden == YES) || (self.alpha <= 0.0f))
		return nil;
	
	if([self pointInside:point withEvent:nil]) {
		TUITextRenderer *textRenderer = [self textRendererAtPoint:point];
		if(textRenderer != nil) {
			return textRenderer;
		}
		
		NSArray *s = [self sortedSubviews];
		for(TUIView *v in [s reverseObjectEnumerator]) {
			TUIView *hit = [v accessibilityHitTest:[self convertPoint:point toView:v]];
			if(hit)
				return hit;
		}
		return self; // leaf
	}
	return nil;
}

- (BOOL)accessibilityIsIgnored
{
    return NO;
}

- (NSArray *)accessibilityAttributeNames
{
    static NSArray *attributes = nil;
    if(attributes == nil) {
		attributes = [[NSArray alloc] initWithObjects:NSAccessibilityRoleAttribute, NSAccessibilityRoleDescriptionAttribute, NSAccessibilityFocusedAttribute, NSAccessibilityChildrenAttribute, NSAccessibilityParentAttribute, NSAccessibilityWindowAttribute, NSAccessibilityTopLevelUIElementAttribute, NSAccessibilityPositionAttribute, NSAccessibilitySizeAttribute, NSAccessibilityDescriptionAttribute, NSAccessibilityValueAttribute, NSAccessibilityTitleAttribute, NSAccessibilityEnabledAttribute, nil];
    }
	
    return attributes;
}

- (id)accessibilityAttributeValue:(NSString *)attribute
{
	id practicalSuperview = (id) self.superview ? : self.nsView;
    if([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
		return [self accessibilityTraitsToRole];
    } else if([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
		return [self accessibilityTraitsToRoleDescription];
    } else if([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
		id focusedElement = [NSApp accessibilityAttributeValue:NSAccessibilityFocusedUIElementAttribute];
		return [NSNumber numberWithBool:[focusedElement isEqual:self]];
    } else if([attribute isEqualToString:NSAccessibilityParentAttribute]) {
		return NSAccessibilityUnignoredAncestor(practicalSuperview);
    } else if([attribute isEqualToString:NSAccessibilityWindowAttribute]) {
		return [practicalSuperview accessibilityAttributeValue:NSAccessibilityWindowAttribute];
    } else if([attribute isEqualToString:NSAccessibilityTopLevelUIElementAttribute]) {
		return [practicalSuperview accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
    } else if([attribute isEqualToString:NSAccessibilityPositionAttribute]) {
		return [NSValue valueWithPoint:[self accessibilityFrame].origin];
    } else if([attribute isEqualToString:NSAccessibilitySizeAttribute]) {
		return [NSValue valueWithSize:[self accessibilityFrame].size];
    } else if([attribute isEqualToString:NSAccessibilityChildrenAttribute]) {
		return [self accessibleSubviews];
	} else if([attribute isEqualToString:NSAccessibilityDescriptionAttribute]) {
		return self.accessibilityHint;
	} else if([attribute isEqualToString:NSAccessibilityValueAttribute]) {
		return self.accessibilityValue;
	} else if([attribute isEqualToString:NSAccessibilityTitleAttribute]) {
		return self.accessibilityLabel;
	} else if([attribute isEqualToString:NSAccessibilityEnabledAttribute]) {
		return [NSNumber numberWithBool:self.userInteractionEnabled];
	}else {
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

- (id)accessibilityFocusedUIElement
{
    return NSAccessibilityUnignoredAncestor(self);
}


#pragma mark API

- (NSString *)accessibilityTraitsToRole
{
	if((self.accessibilityTraits & TUIAccessibilityTraitButton) != 0) {
		return NSAccessibilityButtonRole;
	} else if((self.accessibilityTraits & TUIAccessibilityTraitLink) != 0) {
		return NSAccessibilityLinkRole;
	} else if((self.accessibilityTraits & TUIAccessibilityTraitStaticText) != 0) {
		return NSAccessibilityStaticTextRole;
	} else {
		return NSAccessibilityUnknownRole;
	}
}

- (NSString *)accessibilityTraitsToRoleDescription
{
	// use this handy function for now--might want to customize this more later on
	return NSAccessibilityRoleDescriptionForUIElement(self);
}

- (NSArray *)accessibleSubviews
{
	NSMutableArray *accessibleSubviews = [NSMutableArray array];
	for(TUITextRenderer *renderer in self.textRenderers) {
		[accessibleSubviews addObject:renderer];
	}
	
	for(TUIView *view in self.subviews) {
		if([view isAccessibilityElement]) {
			[accessibleSubviews addObject:view];
		}
	}
	
	return [accessibleSubviews copy];
}

@end
