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
	__unsafe_unretained id accessibilityContainer;
	NSString *accessibilityLabel;
}

@property (nonatomic, unsafe_unretained) id accessibilityContainer;
@property (nonatomic, copy) NSString *accessibilityLabel;

@end
