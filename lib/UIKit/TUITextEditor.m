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

#import "TUIKit.h"
#import "TUITextEditor.h"

@implementation TUITextEditor

@synthesize defaultAttributes;
@synthesize markedAttributes;
@dynamic selectedRange; // getter in TUITextRenderer

- (id)init
{
	if((self = [super init]))
	{
		backingStore = [[NSMutableAttributedString alloc] initWithString:@""];
		markedRange = NSMakeRange(NSNotFound, 0);
		inputContext = [[NSTextInputContext alloc] initWithClient:self];
		inputContext.acceptsGlyphInfo = YES; // fucker
		
		self.attributedString = backingStore;
	}
	return self;
}


- (NSTextInputContext *)inputContext
{
	return inputContext;
}

- (NSMutableAttributedString *)backingStore
{
	return backingStore;
}

- (void)setFrame:(CGRect)f
{
	[super setFrame:f];
	[inputContext invalidateCharacterCoordinates];
}

- (BOOL)becomeFirstResponder
{
	[view setNeedsDisplay];
	return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
	[view setNeedsDisplay];
	return [super resignFirstResponder];
}

- (void)_textDidChange
{
	[inputContext invalidateCharacterCoordinates];
	[self reset];
	[view setNeedsDisplay];
	[view performSelector:@selector(_textDidChange)];
}

- (NSString *)text
{
	return [backingStore string];
}

- (void)setText:(NSString *)aString
{
    [backingStore beginEditing];
    [backingStore replaceCharactersInRange:NSMakeRange(0, [backingStore length]) withString:aString];
    [backingStore setAttributes:defaultAttributes range:NSMakeRange(0, [aString length])];
    [backingStore endEditing];
	
    [self unmarkText];
	self.selectedRange = NSMakeRange([aString length], 0);
	[self _textDidChange];
}

- (void)cut:(id)sender
{
	[self copy:sender];
	[self deleteBackward:nil];
}

- (void)paste:(id)sender
{
	[self insertText:[[NSPasteboard generalPasteboard] stringForType:NSPasteboardTypeString]];
}

- (void)keyDown:(NSEvent *)event
{
	[inputContext handleEvent:event]; // transform into commands
}

- (void)deleteCharactersInRange:(NSRange)range // designated delete
{
	if(range.length == 0)
		return;
	
	// Update the marked range
	if(NSLocationInRange(NSMaxRange(range), markedRange)) {
		markedRange.length -= NSMaxRange(range) - markedRange.location;
		markedRange.location = range.location;
	} else if(markedRange.location > range.location) {
		markedRange.location -= range.length;
	}
	
	if(markedRange.length == 0) {
		[self unmarkText];
	}
	
	// Actually delete the characters
	[backingStore deleteCharactersInRange:range];
	
	NSRange selectedRange;
	selectedRange.location = range.location;
	selectedRange.length = 0;
	self.selectedRange = selectedRange;
	[self _textDidChange];
}






//http://developer.apple.com/library/mac/#samplecode/TextInputView/Listings/FadingTextView_m.html%23//apple_ref/doc/uid/DTS40008840-FadingTextView_m-DontLinkElementID_6

- (void)doCommandBySelector:(SEL)selector
{
	[super doCommandBySelector:selector];
}

- (void)insertText:(id)aString
{
	[self insertText:aString replacementRange:NSMakeRange(NSNotFound, 0)];
}

- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange // designated insert
{
	if(!aString)
		return;
	
	if([aString isKindOfClass:[NSAttributedString class]]) {
		aString = [(NSAttributedString *)aString string];
	}
	
	NSRange selectedRange = [self selectedRange];
	
	// Get a valid range
    if (replacementRange.location == NSNotFound) {
        if (markedRange.location != NSNotFound) {
            replacementRange = markedRange;
        } else {
            replacementRange = selectedRange;
        }
    }
	
    // Add the text
    [backingStore beginEditing];
	[backingStore replaceCharactersInRange:replacementRange withString:aString];
    [backingStore setAttributes:defaultAttributes range:NSMakeRange(replacementRange.location, [aString length])];
    [backingStore endEditing];
	
    // Redisplay
	selectedRange.location = replacementRange.location + [aString length];
	selectedRange.length = 0;
    [self unmarkText];
	self.selectedRange = selectedRange;
	[self _textDidChange];
}

/* The receiver inserts aString replacing the content specified by replacementRange. 
 aString can be either an NSString or NSAttributedString instance. 
 selectedRange specifies the selection inside the string being inserted; 
 hence, the location is relative to the beginning of aString. 
 When aString is an NSString, the receiver is expected to render the marked 
 text with distinguishing appearance (i.e. NSTextView renders with -markedTextAttributes).
 */
- (void)setMarkedText:(id)aString selectedRange:(NSRange)newSelection replacementRange:(NSRange)replacementRange
{
	NSRange selectedRange = [self selectedRange];
	
	if(replacementRange.location == NSNotFound) {
		if (markedRange.location != NSNotFound) {
			replacementRange = markedRange;
		} else {
			replacementRange = selectedRange;
		}
	}
	
    // Add the text
    [backingStore beginEditing];
    if ([aString length] == 0) {
        [backingStore deleteCharactersInRange:replacementRange];
        [self unmarkText];
    } else {
        markedRange = NSMakeRange(replacementRange.location, [aString length]);
        if ([aString isKindOfClass:[NSAttributedString class]]) {
            [backingStore replaceCharactersInRange:replacementRange withAttributedString:aString];
        } else {
            [backingStore replaceCharactersInRange:replacementRange withString:aString];
        }
        [backingStore addAttributes:markedAttributes range:markedRange];
    }
    [backingStore endEditing];
    
    // Redisplay
    selectedRange.location = replacementRange.location + newSelection.location; // Just for now, only select the marked text
    selectedRange.length = newSelection.length;
	self.selectedRange = selectedRange;
	[self _textDidChange];
}

/* The receiver unmarks the marked text. If no marked text, the invocation of this 
 method has no effect.
 */
- (void)unmarkText
{
//	NSLog(@"unmarkText");
	markedRange = NSMakeRange(NSNotFound, 0);
    [inputContext discardMarkedText];
}

- (void)setSelectedRange:(NSRange)r
{
	[self setSelection:r]; // will reset selectionAffinity to per-character
	[view setNeedsDisplay];
}

/* Returns the marked range. Returns {NSNotFound, 0} if no marked range.
 */
- (NSRange)markedRange
{
	//	NSLog(@"markedRange");
	return markedRange;
}

/* Returns whether or not the receiver has marked text.
 */
- (BOOL)hasMarkedText
{
	//	NSLog(@"hasMarkedText");
	return (markedRange.location != NSNotFound);
}

/* Returns attributed string specified by aRange. It may return nil. 
 If non-nil return value and actualRange is non-NULL, it contains the actual range 
 for the return value. The range can be adjusted from various reasons 
 (i.e. adjust to grapheme cluster boundary, performance optimization, etc).
 */
- (NSAttributedString *)attributedSubstringForProposedRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange
{
	NSRange r = NSIntersectionRange(aRange, NSMakeRange(0, [backingStore length]));
	if(actualRange)
		*actualRange = r;
	
	return [backingStore attributedSubstringFromRange:aRange];
}

/* Returns an array of attribute names recognized by the receiver.
 */
- (NSArray *)validAttributesForMarkedText
{
	// We only allow these attributes to be set on our marked text (plus standard attributes)
	// NSMarkedClauseSegmentAttributeName is important for CJK input, among other uses
	// NSGlyphInfoAttributeName allows alternate forms of characters
	return [NSArray arrayWithObjects:NSMarkedClauseSegmentAttributeName, NSGlyphInfoAttributeName, nil];
}

/* Returns the first logical rectangular area for aRange. The return value is in the screen 
 coordinate. The size value can be negative if the text flows to the left. 
 If non-NULL, actuallRange contains the character range corresponding to the returned area.
 */
- (NSRect)firstRectForCharacterRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange
{
	NSRange r = NSIntersectionRange(aRange, NSMakeRange(0, [backingStore length]));
	if(actualRange)
		*actualRange = r;
	CGRect f = [self firstRectForCharacterRange:CFRangeMake(r.location, r.length)];
	NSRect vf = [view frameInNSView];
	
	NSPoint globalViewOffset = [[view nsWindow] convertBaseToScreen:[[view nsView] convertPointToBase:NSZeroPoint]];
	
	NSPoint origin;
	origin.x = globalViewOffset.x + vf.origin.x + f.origin.x;
	origin.y = globalViewOffset.y + vf.origin.y + f.origin.y;
	
	NSRect screenRect;
	screenRect.origin = origin;
	screenRect.size.width = f.size.width;
	screenRect.size.height = f.size.height;
	
	return screenRect;
}

/* Returns the index for character that is nearest to aPoint. aPoint is in the 
 screen coordinate system.
 */
- (NSUInteger)characterIndexForPoint:(NSPoint)screenPoint
{
	NSPoint locationInWindow = [[view nsWindow] convertScreenToBase:screenPoint];
	CGPoint vp = [view localPointForLocationInWindow:locationInWindow];
	
	CGRect trFrame = self.frame;
	vp.x -= trFrame.origin.x;
	vp.y -= trFrame.origin.y;
	CFIndex index = [self stringIndexForPoint:vp];
	return (NSUInteger)index;
}

#pragma mark optional
/* Returns an attributed string representing the receiver's document content. 
 An NSTextInputClient can implement this interface if can be done efficiently. 
 The caller of this interface can random access arbitrary portions of the 
 receiver's content more efficiently.
 */
- (NSAttributedString *)attributedString
{
	return backingStore;
}

/* Returns the fraction of distance for aPoint from the left side of the character. 
 This allows caller to perform precise selection handling.
 */
#if 1
- (CGFloat)fractionOfDistanceThroughGlyphForPoint:(NSPoint)aPoint
{
	return 0.0;
}
#endif

/* Returns the baseline position relative to the origin of rectangle returned 
 by -firstRectForCharacterRange:actualRange:. This information allows the caller 
 to access finer-grained character position inside the NSTextInputClient document.
 */
#if 1
- (CGFloat)baselineDeltaForCharacterAtIndex:(NSUInteger)anIndex
{
	return 0.0;
}
#endif

/* Returns the window level of the receiver. An NSTextInputClient can implement 
 this interface to specify its window level if it is higher than NSFloatingWindowLevel.
 */
- (NSInteger)windowLevel
{
	return [[view nsWindow] level];
}

/* Returns if the marked text is in vertical layout.
 */
- (BOOL)drawsVerticallyForCharacterAtIndex:(NSUInteger)charIndex
{
	return NO;
}

@end
