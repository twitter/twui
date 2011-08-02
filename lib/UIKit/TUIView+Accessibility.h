//
//  TUIView+Accessibility.h
//  TwUI
//
//  Created by Josh Abernathy on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TUIView.h"
#import "TUIAccessibility.h"


@interface TUIView (Accessibility)

@property (nonatomic, assign) BOOL isAccessibilityElement;
@property (nonatomic, copy) NSString *accessibilityLabel;
@property (nonatomic, copy) NSString *accessibilityHint;
@property (nonatomic, copy) NSString *accessibilityValue;
@property (nonatomic, assign) TUIAccessibilityTraits accessibilityTraits;
@property (nonatomic, assign) CGRect accessibilityFrame; // accessibilityFrame should be in screen coordinates

- (NSArray *)accessibleSubviews;

@end
