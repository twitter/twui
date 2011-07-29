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

#import "TUIResponder.h"
#import "ABActiveRange.h"

@class TUIColor;
@class TUIFont;
@class TUIView;

typedef enum {
	TUITextSelectionAffinityCharacter = 0,
	TUITextSelectionAffinityWord = 1,
	TUITextSelectionAffinityLine = 2,
	TUITextSelectionAffinityParagraph = 3,
} TUITextSelectionAffinity;

@protocol TUITextRendererDelegate;

@interface TUITextRenderer : TUIResponder
{
	NSAttributedString *attributedString;
	CGRect frame;
	TUIView *view; // weak
	
	CTFramesetterRef _ct_framesetter;
	CGPathRef _ct_path;
	CTFrameRef _ct_frame;
	
	CFIndex _selectionStart;
	CFIndex _selectionEnd;
	TUITextSelectionAffinity _selectionAffinity;
	
	id<TUITextRendererDelegate> delegate;
	id<ABActiveTextRange> hitRange;
	
	CGSize shadowOffset;
	CGFloat shadowBlur;
	TUIColor *shadowColor;
	
	struct {
		unsigned int drawMaskDragSelection:1;
		unsigned int backgroundDrawingEnabled:1;
		unsigned int preDrawBlocksEnabled:1;
	} _flags;
}

@property (nonatomic, retain) NSAttributedString *attributedString;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) TUIView *view; // weak, remember to set to nil before view goes away

@property (nonatomic, assign) CGSize shadowOffset;
@property (nonatomic, assign) CGFloat shadowBlur;
@property (nonatomic, retain) TUIColor *shadowColor; // default = nil for no shadow

// These are both advanced features that carry with them a potential performance hit.
@property (nonatomic, assign) BOOL backgroundDrawingEnabled; // default = NO
@property (nonatomic, assign) BOOL preDrawBlocksEnabled; // default = NO

- (void)draw;
- (void)drawInContext:(CGContextRef)context;
- (CGSize)size; // calculates vertical size based on frame width
- (CGSize)sizeConstrainedToWidth:(CGFloat)width;
- (void)reset;

- (NSRange)selectedRange;
- (void)setSelection:(NSRange)selection;
- (NSString *)selectedString;

- (CGRect)firstRectForCharacterRange:(CFRange)range;
- (NSArray *)rectsForCharacterRange:(CFRange)range;

@property (nonatomic, retain) id<ABActiveTextRange> hitRange;

@end

#import "TUITextRenderer+Event.h"

NS_INLINE NSRange ABNSRangeFromCFRange(CFRange r) { return NSMakeRange(r.location, r.length); }
NS_INLINE CFRange ABCFRangeFromNSRange(NSRange r) { return CFRangeMake(r.location, r.length); }
