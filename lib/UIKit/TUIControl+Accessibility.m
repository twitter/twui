//
//  TUIControl+Accessibility.m
//  TwUI
//
//  Created by Josh Abernathy on 7/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TUIControl+Accessibility.h"


@implementation TUIControl (Accessibility)


#pragma mark NSAccessibility

- (NSArray *)accessibilityActionNames
{
    return [self allControlEvents] != 0 ? [NSArray arrayWithObject:NSAccessibilityPressAction] : [super accessibilityActionNames];
}

- (NSString *)accessibilityActionDescription:(NSString *)action
{
    if([action isEqualToString:NSAccessibilityPressAction]) {
		return NSLocalizedString(@"press", @"");
	} else {
		return nil;
	}
}

- (void)accessibilityPerformAction:(NSString *)action
{
	if([action isEqualToString:NSAccessibilityPressAction]) {
		[self sendActionsForControlEvents:TUIControlEventAllMouseEvents];
	}
}

@end
