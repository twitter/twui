//
//  TUIAccessibilityElement.h
//  TwUI
//
//  Created by Josh Abernathy on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


// implements the TUIAccessibility informal protocol
@interface TUIAccessibilityElement : NSObject {
	id accessibilityContainer;
	NSString *accessibilityLabel;
}

@property (nonatomic, assign) id accessibilityContainer;
@property (nonatomic, copy) NSString *accessibilityLabel;

@end
