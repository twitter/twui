//
//  TUIButton+Accessibility.m
//  TwUI
//
//  Created by Josh Abernathy on 7/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TUIButton+Accessibility.h"


@implementation TUIButton (Accessibility)

- (NSString *)accessibilityLabel
{
	if(accessibilityLabel == nil) {
		return [self currentTitle];
	}
	
	return accessibilityLabel;
}

@end
