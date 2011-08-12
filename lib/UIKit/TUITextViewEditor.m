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
	BOOL consumed = [[self _textView] doCommandBySelector:selector];
	if(!consumed) {
		[super doCommandBySelector:selector];
	}
}

@end
