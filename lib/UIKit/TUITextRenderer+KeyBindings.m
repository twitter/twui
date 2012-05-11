/*
 Copyright 2011 Twitter, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this work except in compliance with the License.
 You may obtain a copy of the License in the LICENSE file, or at:
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "TUITextRenderer.h"
#import "TUITextEditor.h"
#import "TUIView.h"

@interface NSString (ABTokenizerAdditions)
@end

@implementation NSString (ABTokenizerAdditions)

- (CFIndex)ab_endOfWordGivenCursor:(CFIndex)cursor // if cursor is in word, return end of current word, if past, end of next word
{
	__block CFIndex ret = -1;
	[self enumerateSubstringsInRange:NSMakeRange(0, [self length]) 
							 options:NSStringEnumerationByWords|NSStringEnumerationSubstringNotRequired
						  usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
							  CFIndex l = substringRange.location + substringRange.length;
							  if(l > cursor) {
								  ret = l;
								  *stop = YES;
							  }
						  }];
	if(ret == -1) {
		ret = [self length]; // go to end
	}
	return ret;
}

- (CFIndex)ab_beginningOfWordGivenCursor:(CFIndex)cursor // if cursor is in word, return end of current word, if past, end of next word
{
	__block CFIndex ret = -1;
	[self enumerateSubstringsInRange:NSMakeRange(0, [self length]) 
							 options:NSStringEnumerationByWords|NSStringEnumerationReverse|NSStringEnumerationSubstringNotRequired
						  usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
							  CFIndex l = substringRange.location;
							  if(l < cursor) {
								  ret = l;
								  *stop = YES;
							  }
						  }];
	if(ret == -1) {
		ret = 0; // go to beginning
	}
	return ret;
}

@end


@implementation TUITextRenderer (KeyBindings)

#define TEXT [attributedString string]

- (TUITextEditor *)_textEditor
{
	if([self isKindOfClass:[TUITextEditor class]])
		return (TUITextEditor *)self;
	return nil;
}

- (void)moveRight:(id)sender
{
	NSInteger selectionLength = abs((int)(_selectionStart - _selectionEnd));
	NSInteger max = [TEXT length];
	_selectionStart = _selectionEnd = MIN(MAX(_selectionStart, _selectionEnd) + (selectionLength?0:1), max);
	[self.view setNeedsDisplay];
}

- (void)moveLeft:(id)sender
{
	NSInteger selectionLength = abs((int)(_selectionStart - _selectionEnd));
	NSInteger min = 0;
	_selectionStart = _selectionEnd = MAX(MIN(_selectionStart, _selectionEnd) - (selectionLength?0:1), min);
	[self.view setNeedsDisplay];
}

- (void)moveRightAndModifySelection:(id)sender
{
	NSInteger max = [TEXT length];
	_selectionEnd = MIN(_selectionEnd + 1, max);
	[self.view setNeedsDisplay];
}

- (void)moveLeftAndModifySelection:(id)sender
{
	NSInteger min = 0;
	_selectionEnd = MAX(_selectionEnd - 1, min);
	[self.view setNeedsDisplay];
}

- (void)moveWordRight:(id)sender
{
	_selectionStart = _selectionEnd = [TEXT ab_endOfWordGivenCursor:MAX(_selectionStart, _selectionEnd)];
	[self.view setNeedsDisplay];
}

- (void)moveWordLeft:(id)sender
{
	_selectionStart = _selectionEnd = [TEXT ab_beginningOfWordGivenCursor:MIN(_selectionStart, _selectionEnd)];
	[self.view setNeedsDisplay];
}

- (void)moveWordRightAndModifySelection:(id)sender
{
	_selectionEnd = [TEXT ab_endOfWordGivenCursor:_selectionEnd];
	[self.view setNeedsDisplay];
}

- (void)moveWordLeftAndModifySelection:(id)sender
{
	_selectionEnd = [TEXT ab_beginningOfWordGivenCursor:_selectionEnd];
	[self.view setNeedsDisplay];
}

- (void)moveToBeginningOfLineAndModifySelection:(id)sender
{
	_selectionEnd = 0; // fixme for multiline
	[self.view setNeedsDisplay];
}

- (void)moveToEndOfLineAndModifySelection:(id)sender
{
	_selectionEnd = [TEXT length]; // fixme for multiline
	[self.view setNeedsDisplay];
}

- (void)moveToBeginningOfLine:(id)sender
{
	_selectionStart = _selectionEnd = 0;
	[self.view setNeedsDisplay];
}

- (void)moveToEndOfLine:(id)sender
{
	_selectionStart = _selectionEnd = [TEXT length];
	[self.view setNeedsDisplay];
}

- (void)insertNewline:(id)sender
{
	[[self _textEditor] insertText:@"\n"];
}

- (void)deleteBackward:(id)sender
{
    // Find the range to delete, handling an empty selection and the input point being at 0
	NSRange deleteRange = [self selectedRange];
	if(deleteRange.length == 0) {
		if(deleteRange.location == 0) {
			return;
		} else {
			deleteRange.location -= 1;
			deleteRange.length = 1;
		}
	}
    
    [[self _textEditor] deleteCharactersInRange:deleteRange];
}

- (void)deleteForward:(id)sender
{
    // Find the range to delete, handling an empty selection and the input point being at the end
	NSRange deleteRange = [self selectedRange];
	if(deleteRange.length == 0) {
		if(deleteRange.location == [TEXT length]) {
			return;
		} else {
			deleteRange.length = 1;
		}
	}
    
    [[self _textEditor] deleteCharactersInRange:deleteRange];
}


- (void)deleteToBeginningOfLine:(id)sender
{
	NSInteger selectionLength = abs((int)(_selectionStart - _selectionEnd));
	if(selectionLength == 0) {
		[[self _textEditor] deleteCharactersInRange:NSMakeRange(0, _selectionStart)];
	} else {
		[self deleteBackward:nil];
	}
}

- (void)deleteWordBackward:(id)sender
{
	NSInteger selectionLength = abs((int)(_selectionStart - _selectionEnd));
	if(selectionLength == 0) {
		_selectionEnd = [TEXT ab_beginningOfWordGivenCursor:_selectionEnd];
		[self deleteBackward:nil];
	} else {
		[self deleteBackward:nil];
	}
}

- (void)moveToBeginningOfParagraph:(id)sender
{
	CFIndex cursor = MIN(_selectionStart, _selectionEnd);
	__block CFIndex ret = -1;
	[TEXT enumerateSubstringsInRange:NSMakeRange(0, [TEXT length]) options:NSStringEnumerationByParagraphs | NSStringEnumerationReverse | NSStringEnumerationSubstringNotRequired usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		CFIndex l = substringRange.location;
		if(l < cursor) {
			ret = l;
			*stop = YES;
		}
	}];
	
	if(ret == -1) {
		ret = 0;
	}
	
	_selectionStart = _selectionEnd = ret;
		
	[self.view setNeedsDisplay];
}

- (void)moveToEndOfParagraph:(id)sender
{
	CFIndex cursor = MAX(_selectionStart, _selectionEnd);
	__block CFIndex ret = -1;
	[TEXT enumerateSubstringsInRange:NSMakeRange(0, [TEXT length]) options:NSStringEnumerationByParagraphs | NSStringEnumerationSubstringNotRequired usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		CFIndex l = substringRange.location + substringRange.length;
		if(l > cursor) {
			ret = l;
			*stop = YES;
		}
	}];
	
	if(ret == -1) {
		ret = [TEXT length];
	}
	
	_selectionStart = _selectionEnd = ret;
	
	[self.view setNeedsDisplay];
}

- (void)moveToBeginningOfDocument:(id)sender
{
	_selectionStart = _selectionEnd = 0;
	
	[self.view setNeedsDisplay];
}

- (void)moveToEndOfDocument:(id)sender
{
	_selectionStart = _selectionEnd = [TEXT length];
	
	[self.view setNeedsDisplay];
}

@end
