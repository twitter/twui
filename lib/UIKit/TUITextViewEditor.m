//
//  TUITextViewEditor.m
//  TwUI
//
//  Created by Josh Abernathy on 8/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TUITextViewEditor.h"
#import "TUITextView.h"

@implementation TUITextViewEditor

- (TUITextView *)_textView
{
	return (TUITextView *)view;
}

- (void)doCommandBySelector:(SEL)selector
{
	return [super doCommandBySelector:selector];
}

- (BOOL)becomeFirstResponder
{
	self.selectedRange = NSMakeRange(self.text.length, 0);
	return [super becomeFirstResponder];
}

@end
