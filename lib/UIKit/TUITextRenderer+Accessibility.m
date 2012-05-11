//
//  TUITextRenderer+Accessibility.m
//  TwUI
//
//  Created by Josh Abernathy on 10/27/11.
//  Copyright (c) 2011 Maybe Apps, LLC. All rights reserved.
//

#import "TUITextRenderer+Accessibility.h"
#import "TUIView.h"


@implementation TUITextRenderer (Accessibility)


#pragma mark NSAccessibility

- (id)accessibilityHitTest:(NSPoint)point
{
	return self;
	
	if(CGRectContainsPoint(self.frame, point)) {
		return self;
	} else {
		return nil;
	}
}

- (BOOL)accessibilityIsIgnored
{
    return NO;
}

- (NSArray *)accessibilityAttributeNames
{
    static NSArray *attributes = nil;
    if(attributes == nil) {
		attributes = [[NSArray alloc] initWithObjects:NSAccessibilityRoleAttribute, NSAccessibilityRoleDescriptionAttribute, NSAccessibilityFocusedAttribute, NSAccessibilityChildrenAttribute, NSAccessibilityParentAttribute, NSAccessibilityWindowAttribute, NSAccessibilityTopLevelUIElementAttribute, NSAccessibilityPositionAttribute, NSAccessibilitySizeAttribute, NSAccessibilityDescriptionAttribute, NSAccessibilityValueAttribute, NSAccessibilityEnabledAttribute, nil];
    }
	
    return attributes;
}

- (id)accessibilityAttributeValue:(NSString *)attribute
{
	id practicalSuperview = (id) self.view;
    if([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
		return NSAccessibilityStaticTextRole;
    } else if([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
		return NSAccessibilityStaticTextRole;
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
		CGRect viewFrame = [self.view frameInNSView];
		
		NSPoint p = [[(NSView *)[self.view nsView] window] convertBaseToScreen:NSMakePoint(viewFrame.origin.x + self.frame.origin.x, viewFrame.origin.y + self.frame.origin.y)];
		return [NSValue valueWithPoint:p];
    } else if([attribute isEqualToString:NSAccessibilitySizeAttribute]) {
		return [NSValue valueWithSize:[self frame].size];
    } else if([attribute isEqualToString:NSAccessibilityChildrenAttribute]) {
		return [NSArray array];
	} else if([attribute isEqualToString:NSAccessibilityDescriptionAttribute]) {
		return [self.attributedString string];
	} else if([attribute isEqualToString:NSAccessibilityValueAttribute]) {
		return [self.attributedString string];
	} else if([attribute isEqualToString:NSAccessibilityTitleAttribute]) {
		return [self.attributedString string];
	} else if([attribute isEqualToString:NSAccessibilityEnabledAttribute]) {
		return [NSNumber numberWithBool:YES];
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

@end
