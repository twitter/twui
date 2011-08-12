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
#import "TUITextView.h"
#import "TUITextViewEditor.h"

@implementation TUITextView

@synthesize delegate;
@synthesize drawFrame;
@synthesize font;
@synthesize textColor;
@synthesize textAlignment;
@synthesize editable;
@synthesize contentInset;
@synthesize placeholder;

- (void)_updateDefaultAttributes
{
	renderer.defaultAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
						 (id)[self.font ctFont], kCTFontAttributeName,
						 [self.textColor CGColor], kCTForegroundColorAttributeName,
						 ABNSParagraphStyleForTextAlignment(textAlignment), NSParagraphStyleAttributeName,
						 nil];
	renderer.markedAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
						(id)[self.font ctFont], kCTFontAttributeName,
						[self.textColor CGColor], kCTForegroundColorAttributeName,
						ABNSParagraphStyleForTextAlignment(textAlignment), NSParagraphStyleAttributeName,
						nil];
}

- (Class)textEditorClass
{
	return [TUITextViewEditor class];
}

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame])) {
		self.backgroundColor = [TUIColor clearColor];
		
		renderer = [[[self textEditorClass] alloc] init];
		self.textRenderers = [NSArray arrayWithObject:renderer];
		
		cursor = [[TUIView alloc] initWithFrame:CGRectZero];
		cursor.userInteractionEnabled = NO;
		cursor.backgroundColor = [TUIColor linkColor];
		[self addSubview:cursor];
		[cursor release];
		
		self.font = [TUIFont fontWithName:@"HelveticaNeue" size:12];
		self.textColor = [TUIColor blackColor];
		[self _updateDefaultAttributes];
	}
	return self;
}

- (void)dealloc
{
	[renderer release];
	[drawFrame release];
	[font release];
	[textColor release];
	[placeholder release];
	[super dealloc];
}

- (id)forwardingTargetForSelector:(SEL)sel
{
	if([renderer respondsToSelector:sel])
		return renderer;
	return nil;
}

- (void)mouseEntered:(NSEvent *)event
{
	[super mouseEntered:event];
	[[NSCursor IBeamCursor] push];
}

- (void)mouseExited:(NSEvent *)event
{
	[super mouseExited:event];
	[NSCursor pop];
}

- (void)setDelegate:(id <TUITextViewDelegate>)d
{
	delegate = d;
	_textViewFlags.delegateTextViewDidChange = [delegate respondsToSelector:@selector(textViewDidChange:)];
	_textViewFlags.delegateDoCommandBySelector = [delegate respondsToSelector:@selector(textView:doCommandBySelector:)];
}

- (TUIResponder *)initialFirstResponder
{
	return renderer.initialFirstResponder;
}

- (void)setFont:(TUIFont *)f
{
	[f retain];
	[font release];
	font = f;
	[self _updateDefaultAttributes];
}

- (void)setTextColor:(TUIColor *)c
{
	[c retain];
	[textColor release];
	textColor = c;
	[self _updateDefaultAttributes];
}	

- (void)setTextAlignment:(TUITextAlignment)t
{
	textAlignment = t;
	[self _updateDefaultAttributes];
}

- (BOOL)hasText
{
	return [[self text] length] > 0;
}

static CAAnimation *ThrobAnimation()
{
	CAKeyframeAnimation *a = [CAKeyframeAnimation animation];
	a.keyPath = @"opacity";
	a.values = [NSArray arrayWithObjects:
				[NSNumber numberWithFloat:1.0],
				[NSNumber numberWithFloat:1.0],
				[NSNumber numberWithFloat:1.0],
				[NSNumber numberWithFloat:1.0],
				[NSNumber numberWithFloat:1.0],
				[NSNumber numberWithFloat:0.5],
				[NSNumber numberWithFloat:0.0],
				[NSNumber numberWithFloat:0.0],
				[NSNumber numberWithFloat:0.0],
				[NSNumber numberWithFloat:1.0],
				nil];
	a.duration = 1.0;
	a.repeatCount = INT_MAX;
	return a;
}

- (BOOL)singleLine
{
	return NO; // text field returns yes
}

- (CGRect)textRect
{
	CGRect b = self.bounds;
	b.origin.x += contentInset.left;
	b.origin.y += contentInset.bottom;
	b.size.width -= contentInset.left + contentInset.right;
	b.size.height -= contentInset.bottom + contentInset.top;
	if([self singleLine]) {
		b.size.width = 2000; // big enough
	}
	return b;
}

- (BOOL)_isKey // will fix
{
	NSResponder *firstResponder = [self.nsWindow firstResponder];
	if(firstResponder == self) {
		// responder should be on the renderer
		NSLog(@"making renderer first responder");
		[self.nsWindow tui_makeFirstResponder:renderer];
		firstResponder = renderer;
	}
	return (firstResponder == renderer);
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef ctx = TUIGraphicsGetCurrentContext();
	
	if(drawFrame)
		drawFrame(self, rect);
	
	BOOL singleLine = [self singleLine];
	BOOL doMask = singleLine;
	
	CGRect textRect = [self textRect];
	if(!CGRectEqualToRect(textRect, _lastTextRect)) {
		renderer.frame = textRect;
		_lastTextRect = textRect;
	}
	
	if(doMask) {
		CGContextSaveGState(ctx);
		CGContextClipToRoundRect(ctx, self.bounds, floor(rect.size.height / 2));
	}
	
	[renderer draw];
	
	if(doMask) {
		CGContextRestoreGState(ctx);
	}
	
	BOOL key = [self _isKey];
	NSRange selection = [renderer selectedRange];
	if(key && selection.length == 0) {
		cursor.hidden = NO;
		
		BOOL fakeMetrics = ([[renderer backingStore] length] == 0);
		
		if(fakeMetrics) {
			// setup fake stuff - fake character with font
			TUIAttributedString *fake = [TUIAttributedString stringWithString:@"M"];
			fake.font = self.font;
			renderer.attributedString = fake;
			selection = NSMakeRange(0, 0);
		}

		// Ugh. So this seems to be a decent approximation for the height of the cursor. It doesn't always match the native cursor but what ev.
		CGRect r = CGRectIntegral([renderer firstRectForCharacterRange:ABCFRangeFromNSRange(selection)]);
		r.size.width = 2.0f;
		CGRect fontBoundingBox = CTFontGetBoundingBox(self.font.ctFont);
		r.size.height = round(fontBoundingBox.origin.y + fontBoundingBox.size.height);
		r.origin.y += floor(self.font.leading);
//		NSLog(@"ascent: %f, descent: %f, leading: %f, cap height: %f, x-height: %f, bounding: %@", self.font.ascender, self.font.descender, self.font.leading, self.font.capHeight, self.font.xHeight, NSStringFromRect(CTFontGetBoundingBox(self.font.ctFont)));
		
		[TUIView setAnimationsEnabled:NO block:^{
			cursor.frame = r;
		}];
		
		if(fakeMetrics) {
			// restore
			renderer.attributedString = [renderer backingStore];
		}
		
		[cursor.layer removeAnimationForKey:@"opacity"];
		[cursor.layer addAnimation:ThrobAnimation() forKey:@"opacity"];
		
	} else {
		cursor.hidden = YES;
	}
}

- (void)_textDidChange
{
	if(_textViewFlags.delegateTextViewDidChange)
		[delegate textViewDidChange:self];
}

- (NSRange)selectedRange
{
	return [renderer selectedRange];
}

- (void)setSelectedRange:(NSRange)r
{
	[renderer setSelectedRange:r];
}

- (NSString *)text
{
	return renderer.text;
}

- (void)setText:(NSString *)t
{
	[renderer setText:t];
}

- (void)selectAll:(id)sender
{
	[self setSelectedRange:NSMakeRange(0, [self.text length])];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)doCommandBySelector:(SEL)selector
{
	if(_textViewFlags.delegateDoCommandBySelector) {
		return [delegate textView:self doCommandBySelector:selector];
	}
	
	return NO;
}

@end

static void TUITextViewDrawRoundedFrame(TUIView *view, CGFloat radius, BOOL overDark)
{
	CGRect rect = view.bounds;
	CGContextRef ctx = TUIGraphicsGetCurrentContext();
	CGContextSaveGState(ctx);
	
	if(overDark) {
		rect.size.height -= 1;
		
		CGContextSetRGBFillColor(ctx, 1, 1, 1, 0.4);
		CGContextFillRoundRect(ctx, rect, radius);
		
		rect.origin.y += 1;
		
		CGContextSetRGBFillColor(ctx, 0, 0, 0, 0.65);
		CGContextFillRoundRect(ctx, rect, radius);
	} else {
		rect.size.height -= 1;
		
		CGContextSetRGBFillColor(ctx, 1, 1, 1, 0.5);
		CGContextFillRoundRect(ctx, rect, radius);
		
		rect.origin.y += 1;
		
		CGContextSetRGBFillColor(ctx, 0, 0, 0, 0.35);
		CGContextFillRoundRect(ctx, rect, radius);
	}
	
	rect = CGRectInset(rect, 1, 1);
	CGContextClipToRoundRect(ctx, rect, radius);
	CGFloat a = 0.9;
	CGFloat b = 1.0;
	CGFloat colorA[] = {a, a, a, 1.0};
	CGFloat colorB[] = {b, b, b, 1.0};
	CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
	CGContextFillRect(ctx, rect);
	CGContextDrawLinearGradientBetweenPoints(ctx, CGPointMake(0, rect.size.height+5), colorA, CGPointMake(0, 5), colorB);
	
	CGContextRestoreGState(ctx);
}

TUIViewDrawRect TUITextViewSearchFrame(void)
{
	return [[^(TUIView *view, CGRect rect) {
		TUITextViewDrawRoundedFrame(view, 	floor(view.bounds.size.height / 2), NO);
	} copy] autorelease];
}

TUIViewDrawRect TUITextViewSearchFrameOverDark(void)
{
	return [[^(TUIView *view, CGRect rect) {
		TUITextViewDrawRoundedFrame(view, 	floor(view.bounds.size.height / 2), YES);
	} copy] autorelease];
}
