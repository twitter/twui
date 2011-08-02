//
//  TUIAccessibilityElement.m
//  TwUI
//
//  Created by Josh Abernathy on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TUIAccessibilityElement.h"


@implementation TUIAccessibilityElement

@synthesize accessibilityContainer;
@synthesize accessibilityLabel;

- (void)dealloc
{
	[accessibilityLabel release];
	
	[super dealloc];
}

- (id)initWithAccessibilityContainer:(id)container
{
    self = [super init];
    if(self == nil) {
		[self release];
		return nil;
	}
	
	self.accessibilityContainer = container;
    
    return self;
}

@end
