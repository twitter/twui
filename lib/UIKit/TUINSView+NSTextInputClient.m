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

#import "TUINSView+NSTextInputClient.h"
#import "TUINSView+Private.h"
#import "TUINSWindow.h"
#import "TUITextRenderer.h"

@implementation TUINSView (NSTextInputClient)

/*
 This file is jank - TUITextRenderer and friends can shoulder this stuff
 themselves, better.
 */

/* NSTextInputClient call sequence on 10.6
 1. attributedSubstringForProposedRange:actualRange: {0, 10} {0, 10}		<- we have no idea what text area we're being asked about, so just return a dummy string
 2. characterIndexForPoint: {x, y}											<- now we can determine what text area we're being asked about, remember it for later and return the index
 3. attributedSubstringForProposedRange:actualRange: {0, 50} {0, 50}		<- again being probed about some arbitrary range, but we know which one it wants, so we hand it back
 4. firstRectForCharacterRange:actualRange: {8, 4} {8, 4}					<- range of word containing index returned by (2)
 5. 																		<- now we can reset the temporary tracked renderer
 */

- (TUITextRenderer *)_textRendererAtScreenPoint:(NSPoint)screenPoint
{
	NSPoint locationInWindow = [[self window] convertScreenToBase:screenPoint];
	NSPoint localPoint = [self localPointForLocationInWindow:locationInWindow];
	TUIView *v = [self viewForLocalPoint:localPoint];
	CGPoint vPoint = localPoint;
	NSRect vf = [v frameInNSView];
	vPoint.x -= vf.origin.x;
	vPoint.y -= vf.origin.y;
	TUITextRenderer *r = [v textRendererAtPoint:vPoint];
//	NSLog(@"found v = %@", v);
//	NSLog(@"found r = %@", r);
	return r;
}

- (NSAttributedString *)attributedSubstringForProposedRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange
{
//	NSLog(@"%@ %@ %@", NSStringFromSelector(_cmd), NSStringFromRange(aRange), NSStringFromRange(*actualRange));
	
	if(_tempTextRendererForTextInputClient) {
		NSRange r = NSIntersectionRange(aRange, NSMakeRange(0, [_tempTextRendererForTextInputClient.attributedString length]));
		*actualRange = r;
		NSAttributedString *s = [_tempTextRendererForTextInputClient.attributedString attributedSubstringFromRange:r];
//		NSLog(@"know which text renderer I'm dealing with, returning - %@", s);
		return s;
	} else {
//		NSLog(@"ignoring");
		return [[NSAttributedString alloc] initWithString:@"a"]; // dummy string because we have NO clue what text renderer NSTextInputContext is asking about
	}
}

- (NSUInteger)characterIndexForPoint:(NSPoint)screenPoint
{
//	NSLog(@"%@ %@", NSStringFromSelector(_cmd), NSStringFromPoint(screenPoint));
	_tempTextRendererForTextInputClient = [self _textRendererAtScreenPoint:screenPoint];
	if(_tempTextRendererForTextInputClient) {
		NSPoint locationInWindow = [[self window] convertScreenToBase:screenPoint];
		CGPoint vp = [_tempTextRendererForTextInputClient.view localPointForLocationInWindow:locationInWindow];
//		NSLog(@"vp = %@", NSStringFromPoint(vp));
		CGRect trFrame = _tempTextRendererForTextInputClient.frame;
		vp.x -= trFrame.origin.x;
		vp.y -= trFrame.origin.y;
		CFIndex index = [_tempTextRendererForTextInputClient stringIndexForPoint:vp];
//		NSLog(@"index = %d", index);
		return (NSUInteger)index;
	}
	
	return NSNotFound;
}

- (NSRect)firstRectForCharacterRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange
{
//	NSLog(@"%@ %@ %@", NSStringFromSelector(_cmd), NSStringFromRange(aRange), NSStringFromRange(*actualRange));
	
	NSRect ret = NSZeroRect;
	
	if(_tempTextRendererForTextInputClient) {
		NSRange r = NSIntersectionRange(aRange, NSMakeRange(0, [_tempTextRendererForTextInputClient.attributedString length]));
		*actualRange = r;
//		NSLog(@"getting first rect for range: %@", NSStringFromRange(r));
		CGRect f = [_tempTextRendererForTextInputClient firstRectForCharacterRange:CFRangeMake(r.location, r.length)];
//		NSLog(@"f = %@", NSStringFromRect(f));
		NSRect vf = [_tempTextRendererForTextInputClient.view convertRect:f toView:nil];
//		NSLog(@"vf = %@", NSStringFromRect(vf));
		
		NSRect windowRelativeRect = [_tempTextRendererForTextInputClient.view.nsView convertRect:vf toView:nil];
//		NSLog(@"windowRelativeRect = %@", NSStringFromRect(windowRelativeRect));
		
		NSRect screenRect = windowRelativeRect;
		screenRect.origin = [_tempTextRendererForTextInputClient.view.nsWindow convertBaseToScreen:windowRelativeRect.origin];
	
		ret = screenRect;
	}
	
	_tempTextRendererForTextInputClient = nil; // reset (this is the last call in the dictionary-lookup sequence

	return ret;
}

- (void)unmarkText
{
	
}

- (NSArray *)validAttributesForMarkedText
{
	return [NSArray array];
}

- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange
{
	
}

- (BOOL)drawsVerticallyForCharacterAtIndex:(NSUInteger)charIndex
{
	return NO;
}

- (BOOL)hasMarkedText
{
	return NO;
}

- (NSRange)markedRange
{
	return NSMakeRange(NSNotFound, 0);
}

- (NSRange)selectedRange
{
	return NSMakeRange(NSNotFound, 0);
}

- (void)setMarkedText:(id)aString selectedRange:(NSRange)someSelectedRange replacementRange:(NSRange)replacementRange
{
//	NSLog(@"OTHER ONE");
}

- (void)doCommandBySelector:(SEL)aSelector
{
	[self tryToPerform:aSelector with:self];
}

@end
