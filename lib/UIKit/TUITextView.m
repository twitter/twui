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
#import "TUITextRenderer+Event.h"

@interface TUITextViewAutocorrectedPair : NSObject <NSCopying> {
	NSTextCheckingResult *correctionResult;
	NSString *originalString;
}

@property (nonatomic, retain) NSTextCheckingResult *correctionResult;
@property (nonatomic, copy) NSString *originalString;
@end

@implementation TUITextViewAutocorrectedPair
@synthesize correctionResult;
@synthesize originalString;

- (BOOL)isEqual:(id)object {
	if(![object isKindOfClass:[TUITextViewAutocorrectedPair class]]) return NO;
	
	TUITextViewAutocorrectedPair *otherPair = object;
	return [self.originalString isEqualToString:otherPair.originalString] && NSEqualRanges(self.correctionResult.range, otherPair.correctionResult.range);
}

- (NSUInteger)hash {
	return [self.originalString hash] ^ self.correctionResult.range.location ^ self.correctionResult.range.length;
}

- (id)copyWithZone:(NSZone *)zone {
	TUITextViewAutocorrectedPair *copiedPair = [[[self class] alloc] init];
	copiedPair.correctionResult = self.correctionResult;
	copiedPair.originalString = self.originalString;
	return copiedPair;
}
@end

@interface TUITextView () <TUITextRendererDelegate>
- (void)_checkSpelling;
- (void)_replaceMisspelledWord:(NSMenuItem *)menuItem;
- (CGRect)_cursorRect;

@property (nonatomic, strong) NSArray *lastCheckResults;
@property (nonatomic, strong) NSTextCheckingResult *selectedTextCheckingResult;
@property (nonatomic, strong) NSMutableDictionary *autocorrectedResults;
@property (nonatomic, strong) TUITextRenderer *placeholderRenderer;
@end

@implementation TUITextView

@synthesize delegate;
@synthesize drawFrame;
@synthesize font;
@synthesize textColor;
@synthesize textAlignment;
@synthesize editable;
@synthesize contentInset;
@synthesize placeholder;
@synthesize spellCheckingEnabled;
@synthesize lastCheckResults;
@synthesize selectedTextCheckingResult;
@synthesize autocorrectionEnabled;
@synthesize autocorrectedResults;
@synthesize placeholderRenderer;

- (void)_updateDefaultAttributes
{
	renderer.defaultAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
						 (id)[self.font ctFont], kCTFontAttributeName,
						 [self.textColor CGColor], kCTForegroundColorAttributeName,
						 ABNSParagraphStyleForTextAlignment(textAlignment), NSParagraphStyleAttributeName,
						 nil];
	renderer.markedAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
						[NSFont fontWithName:self.font.fontName size:self.font.pointSize], kCTFontAttributeName, // NSFont and CTFont are toll-free bridged. *BUT* for reasons beyond my understanding, advanced input methods like Japanese and simplified Pinyin break unless this is an NSFont. So there we go.
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
		renderer.delegate = self;
		self.textRenderers = [NSArray arrayWithObject:renderer];
		
		cursor = [[TUIView alloc] initWithFrame:CGRectZero];
		cursor.userInteractionEnabled = NO;
		cursor.backgroundColor = [TUIColor linkColor];
		[self addSubview:cursor];
		
		self.autocorrectedResults = [NSMutableDictionary dictionary];
		
		self.font = [TUIFont fontWithName:@"HelveticaNeue" size:12];
		self.textColor = [TUIColor blackColor];
		[self _updateDefaultAttributes];
	}
	return self;
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
	_textViewFlags.delegateWillBecomeFirstResponder = [delegate respondsToSelector:@selector(textViewWillBecomeFirstResponder:)];
	_textViewFlags.delegateDidBecomeFirstResponder = [delegate respondsToSelector:@selector(textViewDidBecomeFirstResponder:)];
	_textViewFlags.delegateWillResignFirstResponder = [delegate respondsToSelector:@selector(textViewWillResignFirstResponder:)];
	_textViewFlags.delegateDidResignFirstResponder = [delegate respondsToSelector:@selector(textViewDidResignFirstResponder:)];
}

- (TUIResponder *)initialFirstResponder
{
	return renderer.initialFirstResponder;
}

- (void)setFont:(TUIFont *)f
{
	font = f;
	[self _updateDefaultAttributes];
}

- (void)setTextColor:(TUIColor *)c
{
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
	static const CGFloat singleLineWidth = 20000.0f;
	
	CGContextRef ctx = TUIGraphicsGetCurrentContext();
	
	if(drawFrame)
		drawFrame(self, rect);
	
	BOOL singleLine = [self singleLine];
	CGRect textRect = [self textRect];
	CGRect rendererFrame = textRect;
	if(singleLine) {
		rendererFrame.size.width = singleLineWidth;
	}
	
	renderer.frame = rendererFrame;
	
	BOOL showCursor = [self _isKey] && [renderer selectedRange].length == 0;
	if(showCursor) {
		cursor.hidden = NO;
		[cursor.layer removeAnimationForKey:@"opacity"];
		[cursor.layer addAnimation:ThrobAnimation() forKey:@"opacity"];
	} else {
		cursor.hidden = YES;
	}
	
	// Single-line text views scroll horizontally with the cursor.
	CGRect cursorFrame = [self _cursorRect];
	CGFloat offset = 0.0f;
	if(singleLine) {
		if(CGRectGetMaxX(cursorFrame) > CGRectGetWidth(textRect)) {
			offset = CGRectGetMinX(cursorFrame) - CGRectGetWidth(textRect);
			rendererFrame = CGRectMake(-offset, rendererFrame.origin.y, CGRectGetWidth(rendererFrame), CGRectGetHeight(rendererFrame));
			cursorFrame = CGRectOffset(cursorFrame, -offset - CGRectGetWidth(cursorFrame) - 5.0f, 0.0f);
			
			renderer.frame = rendererFrame;
		}
	}
	
	if(showCursor) {
		[TUIView setAnimationsEnabled:NO block:^{
			cursor.frame = cursorFrame;
		}];
	}
	
	BOOL doMask = singleLine;
	if(doMask) {
		CGContextSaveGState(ctx);
		CGFloat radius = floor(rect.size.height / 2);
		CGContextClipToRoundRect(ctx, CGRectInset(textRect, 0.0f, -radius), radius);
	}
	
	[renderer draw];
	
	if(renderer.attributedString.length < 1 && self.placeholder.length > 0) {
		TUIAttributedString *attributedString = [TUIAttributedString stringWithString:self.placeholder];
		attributedString.font = self.font;
		attributedString.color = [self.textColor colorWithAlphaComponent:0.4f];
		
		self.placeholderRenderer.attributedString = attributedString;
		self.placeholderRenderer.frame = rendererFrame;
		[self.placeholderRenderer draw];
	}
	
	if(doMask) {
		CGContextRestoreGState(ctx);
	}
}

- (CGRect)_cursorRect
{
	BOOL fakeMetrics = ([[renderer backingStore] length] == 0);
	NSRange selection = [renderer selectedRange];
	
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
	//NSLog(@"ascent: %f, descent: %f, leading: %f, cap height: %f, x-height: %f, bounding: %@", self.font.ascender, self.font.descender, self.font.leading, self.font.capHeight, self.font.xHeight, NSStringFromRect(CTFontGetBoundingBox(self.font.ctFont)));
	
	if(self.text.length > 0) {
		unichar lastCharacter = [self.text characterAtIndex:MAX(selection.location - 1, 0)];
		// Sigh. So if the string ends with a return, CTFrameGetLines doesn't consider that a new line. So we have to fudge it.
		if(lastCharacter == '\n') {
			CGRect firstCharacterRect = [renderer firstRectForCharacterRange:CFRangeMake(0, 0)];
			r.origin.y -= firstCharacterRect.size.height;
			r.origin.x = firstCharacterRect.origin.x;
		}
	}
	
	if(fakeMetrics) {
		// restore
		renderer.attributedString = [renderer backingStore];
	}
		
	return r;
}

- (void)_textDidChange
{
	if(_textViewFlags.delegateTextViewDidChange)
		[delegate textViewDidChange:self];
	
	if(spellCheckingEnabled) {
		[self _checkSpelling];
	}
}

- (void)_checkSpelling
{
	NSTextCheckingType checkingTypes = NSTextCheckingTypeSpelling;
	if(autocorrectionEnabled) checkingTypes |= NSTextCheckingTypeCorrection | NSTextCheckingTypeReplacement;
	
	NSRange wholeLineRange = NSMakeRange(0, [self.text length]);
	lastCheckToken = [[NSSpellChecker sharedSpellChecker] requestCheckingOfString:self.text range:wholeLineRange types:checkingTypes options:nil inSpellDocumentWithTag:0 completionHandler:^(NSInteger sequenceNumber, NSArray *results, NSOrthography *orthography, NSInteger wordCount) {
		NSRange selectionRange = [self selectedRange];
		__block NSRange activeWordSubstringRange = NSMakeRange(0, 0);
		[self.text enumerateSubstringsInRange:NSMakeRange(0, [self.text length]) options:NSStringEnumerationByWords | NSStringEnumerationSubstringNotRequired | NSStringEnumerationReverse | NSStringEnumerationLocalized usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
			if(selectionRange.location >= substringRange.location && selectionRange.location <= substringRange.location + substringRange.length) {
				activeWordSubstringRange = substringRange;
				*stop = YES;
			}
		}];
		
		// This needs to happen on the main thread so that the user doesn't enter more text while we're changing the attributed string.
		dispatch_async(dispatch_get_main_queue(), ^{
			// we only care about the most recent results, ignore anything older
			if(sequenceNumber != lastCheckToken) return;
			
			if([self.lastCheckResults isEqualToArray:results]) return;
			
			[[renderer backingStore] beginEditing];
			
			NSRange wholeStringRange = NSMakeRange(0, [self.text length]);
			[[renderer backingStore] removeAttribute:(id)kCTUnderlineColorAttributeName range:wholeStringRange];
			[[renderer backingStore] removeAttribute:(id)kCTUnderlineStyleAttributeName range:wholeStringRange];
			
			NSMutableArray *autocorrectedResultsThisRound = [NSMutableArray array];
			for(NSTextCheckingResult *result in results) {
				// Don't check the word they're typing. It's just annoying.
				BOOL isActiveWord = NSEqualRanges(result.range, activeWordSubstringRange);
				if(selectionRange.length == 0) {
					if(isActiveWord) continue;
					
					// Don't correct if it looks like they might be typing a contraction.
					unichar lastCharacter = [[[renderer backingStore] string] characterAtIndex:self.selectedRange.location - 1];
					if(lastCharacter == '\'') continue;
				}
								
				if(result.resultType == NSTextCheckingTypeCorrection || result.resultType == NSTextCheckingTypeReplacement) {
					NSString *backingString = [[renderer backingStore] string];
					if(NSMaxRange(result.range) <= backingString.length) {
						NSString *oldString = [backingString substringWithRange:result.range];
						TUITextViewAutocorrectedPair *correctionPair = [[TUITextViewAutocorrectedPair alloc] init];
						correctionPair.correctionResult = result;
						correctionPair.originalString = oldString;
						
						// Don't redo corrections that the user undid.
						if([self.autocorrectedResults objectForKey:correctionPair] != nil) continue;
						
						[[renderer backingStore] removeAttribute:(id)kCTUnderlineColorAttributeName range:result.range];
						[[renderer backingStore] removeAttribute:(id)kCTUnderlineStyleAttributeName range:result.range];
						
						[self.autocorrectedResults setObject:oldString forKey:correctionPair];
						[[renderer backingStore] replaceCharactersInRange:result.range withString:result.replacementString];
						[autocorrectedResultsThisRound addObject:result];
						
						// the replacement could have changed the length of the string, so adjust the selection to account for that
						NSInteger lengthChange = result.replacementString.length - oldString.length;
						[self setSelectedRange:NSMakeRange(self.selectedRange.location + lengthChange, self.selectedRange.length)];
					} else {
						NSLog(@"Autocorrection result that's out of range: %@", result);
					}
				} else if(result.resultType == NSTextCheckingTypeSpelling) {
					[[renderer backingStore] addAttribute:(id)kCTUnderlineColorAttributeName value:(id)[TUIColor redColor].CGColor range:result.range];
					[[renderer backingStore] addAttribute:(id)kCTUnderlineStyleAttributeName value:[NSNumber numberWithInteger:kCTUnderlineStyleThick | kCTUnderlinePatternDot] range:result.range];
				}
			}
			
			[[renderer backingStore] endEditing];
			[renderer reset]; // make sure we reset so that the renderer uses our new attributes

			[self setNeedsDisplay];
			
			self.lastCheckResults = results;
		});
	}];
}

- (NSMenu *)menuForEvent:(NSEvent *)event
{
	CFIndex stringIndex = [renderer stringIndexForEvent:event];
	for(NSTextCheckingResult *result in lastCheckResults) {
		if(stringIndex >= result.range.location && stringIndex <= result.range.location + result.range.length) {
			self.selectedTextCheckingResult = result;
			break;
		}
	}
	
	TUITextViewAutocorrectedPair *matchingAutocorrectPair = nil;
	if(selectedTextCheckingResult == nil) {
		for(TUITextViewAutocorrectedPair *correctionPair in self.autocorrectedResults) {
			NSTextCheckingResult *result = correctionPair.correctionResult;
			if(stringIndex >= result.range.location && stringIndex <= result.range.location + result.range.length) {
				self.selectedTextCheckingResult = result;
				matchingAutocorrectPair = correctionPair;
				break;
			}
		}
	}
	
	if(selectedTextCheckingResult == nil) return nil;
		
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
	if(selectedTextCheckingResult.resultType == NSTextCheckingTypeCorrection && matchingAutocorrectPair != nil) {
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Change Back to \"%@\"", @""), matchingAutocorrectPair.originalString] action:@selector(_replaceAutocorrectedWord:) keyEquivalent:@""];
		[menuItem setTarget:self];
		[menuItem setRepresentedObject:matchingAutocorrectPair.originalString];
		[menu addItem:menuItem];
		
		[menu addItem:[NSMenuItem separatorItem]];
	}
	
	NSArray *guesses = [[NSSpellChecker sharedSpellChecker] guessesForWordRange:selectedTextCheckingResult.range inString:[self text] language:nil inSpellDocumentWithTag:0];
	if(guesses.count > 0) {
		for(NSString *guess in guesses) {
			NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:guess action:@selector(_replaceMisspelledWord:) keyEquivalent:@""];
			[menuItem setTarget:self];
			[menuItem setRepresentedObject:guess];
			[menu addItem:menuItem];
		}
	} else {
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"No guesses", @"") action:NULL keyEquivalent:@""];
		[menu addItem:menuItem];
	}
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	[renderer patchMenuWithStandardEditingMenuItems:menu];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	NSMenuItem *spellingAndGrammarItem = [menu addItemWithTitle:NSLocalizedString(@"Spelling and Grammar", @"") action:NULL keyEquivalent:@""];
	NSMenu *spellingAndGrammarMenu = [[NSMenu alloc] initWithTitle:@""];
	[spellingAndGrammarMenu addItemWithTitle:NSLocalizedString(@"Show Spelling and Grammar", @"") action:@selector(showGuessPanel:) keyEquivalent:@""];
	[spellingAndGrammarMenu addItemWithTitle:NSLocalizedString(@"Check Document Now", @"") action:@selector(checkSpelling:) keyEquivalent:@""];
	[spellingAndGrammarMenu addItem:[NSMenuItem separatorItem]];
	[spellingAndGrammarMenu addItemWithTitle:NSLocalizedString(@"Check Spelling While Typing", @"") action:@selector(toggleContinuousSpellChecking:) keyEquivalent:@""];
	[spellingAndGrammarMenu addItemWithTitle:NSLocalizedString(@"Check Grammar With Spelling", @"") action:@selector(toggleGrammarChecking:) keyEquivalent:@""];
	[spellingAndGrammarMenu addItemWithTitle:NSLocalizedString(@"Correct Spelling Automatically", @"") action:@selector(toggleAutomaticSpellingCorrection:) keyEquivalent:@""];
	[spellingAndGrammarItem setSubmenu:spellingAndGrammarMenu];
	
	NSMenuItem *substitutionsItem = [menu addItemWithTitle:NSLocalizedString(@"Substitutions", @"") action:NULL keyEquivalent:@""];
	NSMenu *substitutionsMenu = [[NSMenu alloc] initWithTitle:@""];
	[substitutionsMenu addItemWithTitle:NSLocalizedString(@"Show Substitutions", @"") action:@selector(orderFrontSubstitutionsPanel:) keyEquivalent:@""];
	[substitutionsMenu addItem:[NSMenuItem separatorItem]];
	[substitutionsMenu addItemWithTitle:NSLocalizedString(@"Smart Copy/Paste", @"") action:@selector(toggleSmartInsertDelete:) keyEquivalent:@""];
	[substitutionsMenu addItemWithTitle:NSLocalizedString(@"Smart Quotes", @"") action:@selector(toggleAutomaticQuoteSubstitution:) keyEquivalent:@""];
	[substitutionsMenu addItemWithTitle:NSLocalizedString(@"Smart Dashes", @"") action:@selector(toggleAutomaticDashSubstitution:) keyEquivalent:@""];
	[substitutionsMenu addItemWithTitle:NSLocalizedString(@"Smart Links", @"") action:@selector(toggleAutomaticLinkDetection:) keyEquivalent:@""];
	[substitutionsMenu addItemWithTitle:NSLocalizedString(@"Text Replacement", @"") action:@selector(toggleAutomaticTextReplacement:) keyEquivalent:@""];
	[substitutionsItem setSubmenu:substitutionsMenu];
	
	NSMenuItem *transformationsItem = [menu addItemWithTitle:NSLocalizedString(@"Transformations", @"") action:NULL keyEquivalent:@""];
	NSMenu *transformationsMenu = [[NSMenu alloc] initWithTitle:@""];
	[transformationsMenu addItemWithTitle:NSLocalizedString(@"Make Upper Case", @"") action:@selector(uppercaseWord:) keyEquivalent:@""];
	[transformationsMenu addItemWithTitle:NSLocalizedString(@"Make Lower Case", @"") action:@selector(lowercaseWord:) keyEquivalent:@""];
	[transformationsMenu addItemWithTitle:NSLocalizedString(@"Capitalize", @"") action:@selector(capitalizeWord:) keyEquivalent:@""];
	[transformationsItem setSubmenu:transformationsMenu];
	
	NSMenuItem *speechItem = [menu addItemWithTitle:NSLocalizedString(@"Speech", @"") action:NULL keyEquivalent:@""];
	NSMenu *speechMenu = [[NSMenu alloc] initWithTitle:@""];
	[speechMenu addItemWithTitle:NSLocalizedString(@"Start Speaking", @"") action:@selector(startSpeaking:) keyEquivalent:@""];
	[speechMenu addItemWithTitle:NSLocalizedString(@"Stop Speaking", @"") action:@selector(stopSpeaking:) keyEquivalent:@""];
	[speechItem setSubmenu:speechMenu];
	
	return [self.nsView menuWithPatchedItems:menu];
}

- (void)_replaceMisspelledWord:(NSMenuItem *)menuItem
{
	NSString *oldString = [self.text substringWithRange:self.selectedTextCheckingResult.range];
	NSString *replacement = [menuItem representedObject];
	[[renderer backingStore] beginEditing];
	[[renderer backingStore] removeAttribute:(id)kCTUnderlineColorAttributeName range:selectedTextCheckingResult.range];
	[[renderer backingStore] removeAttribute:(id)kCTUnderlineStyleAttributeName range:selectedTextCheckingResult.range];
	[[renderer backingStore] replaceCharactersInRange:self.selectedTextCheckingResult.range withString:replacement];
	[[renderer backingStore] endEditing];
	[renderer reset];
	
	NSInteger lengthChange = replacement.length - oldString.length;
	[self setSelectedRange:NSMakeRange(self.selectedRange.location + lengthChange, self.selectedRange.length)];
	
	[self _textDidChange];
	
	self.selectedTextCheckingResult = nil;
}

- (void)_replaceAutocorrectedWord:(NSMenuItem *)menuItem
{
	NSString *oldString = [self.text substringWithRange:self.selectedTextCheckingResult.range];
	NSString *replacement = [menuItem representedObject];
	[[renderer backingStore] beginEditing];
	[[renderer backingStore] removeAttribute:(id)kCTUnderlineColorAttributeName range:selectedTextCheckingResult.range];
	[[renderer backingStore] removeAttribute:(id)kCTUnderlineStyleAttributeName range:selectedTextCheckingResult.range];
	[[renderer backingStore] replaceCharactersInRange:self.selectedTextCheckingResult.range withString:replacement];
	[[renderer backingStore] endEditing];
	[renderer reset];
	
	NSInteger lengthChange = replacement.length - oldString.length;
	[self setSelectedRange:NSMakeRange(self.selectedRange.location + lengthChange, self.selectedRange.length)];
	
	[self _textDidChange];
	
	self.selectedTextCheckingResult = nil;
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

- (BOOL)performKeyEquivalent:(NSEvent *)event {
	if([self.nsWindow firstResponder] == renderer) {
		return [renderer performKeyEquivalent:event];
	}
	
	return [super performKeyEquivalent:event];
}

- (BOOL)doCommandBySelector:(SEL)selector
{
	if(_textViewFlags.delegateDoCommandBySelector) {
		BOOL consumed = [delegate textView:self doCommandBySelector:selector];
		if(consumed) return YES;
	}
		
	if(selector == @selector(moveUp:)) {
		if([self singleLine]) {
			self.selectedRange = NSMakeRange(0, 0);
		} else {
			CGRect rect = [renderer firstRectForCharacterRange:ABCFRangeFromNSRange(self.selectedRange)];
			CFIndex aboveIndex = [renderer stringIndexForPoint:CGPointMake(rect.origin.x - rect.size.width, rect.origin.y + rect.size.height*2)];
			self.selectedRange = NSMakeRange(MAX(aboveIndex - 1, 0), 0);
		}
		
		return YES;
	} else if(selector == @selector(moveDown:)) {
		if([self singleLine]) {
			self.selectedRange = NSMakeRange(self.text.length, 0);
		} else {
			CGRect rect = [renderer firstRectForCharacterRange:ABCFRangeFromNSRange(self.selectedRange)];
			CFIndex belowIndex = [renderer stringIndexForPoint:CGPointMake(rect.origin.x - rect.size.width, rect.origin.y)];
			belowIndex = MAX(belowIndex - 1, 0);
			
			// if we're on the same level as the belowIndex, then we've hit the last line and want to go to the end
			CGRect belowRect = [renderer firstRectForCharacterRange:CFRangeMake(belowIndex, 0)];
			if(belowRect.origin.y == rect.origin.y) {
				belowIndex = MIN(belowIndex + 1, self.text.length);
			}
			self.selectedRange = NSMakeRange(belowIndex, 0);
		}
		
		return YES;
	}
	
	return NO;
}

- (TUITextRenderer *)placeholderRenderer {
	if(placeholderRenderer == nil) {
		self.placeholderRenderer = [[TUITextRenderer alloc] init];
	}
	
	return placeholderRenderer;
}

- (CGSize)sizeThatFits:(CGSize)size {
	CGSize textSize = [renderer sizeConstrainedToWidth:CGRectGetWidth([self textRect])];
	// Sigh. So if the string ends with a return, CTFrameGetLines doesn't consider that a new line. So we have to fudge it.
	if([self.text hasSuffix:@"\n"]) {
		CGRect firstCharacterRect = [renderer firstRectForCharacterRange:CFRangeMake(0, 0)];
		textSize.height += firstCharacterRect.size.height;
	}
	
	return CGSizeMake(CGRectGetWidth(self.bounds), textSize.height + contentInset.top + contentInset.bottom);
}


#pragma mark TUITextRendererDelegate

- (void)textRendererWillBecomeFirstResponder:(TUITextRenderer *)textRenderer
{
	if(_textViewFlags.delegateWillBecomeFirstResponder) [delegate textViewWillBecomeFirstResponder:self];
}

- (void)textRendererDidBecomeFirstResponder:(TUITextRenderer *)textRenderer
{
	if(_textViewFlags.delegateDidBecomeFirstResponder) [delegate textViewDidBecomeFirstResponder:self];
}

- (void)textRendererWillResignFirstResponder:(TUITextRenderer *)textRenderer
{
	if(_textViewFlags.delegateWillResignFirstResponder) [delegate textViewWillResignFirstResponder:self];
}

- (void)textRendererDidResignFirstResponder:(TUITextRenderer *)textRenderer
{
	if(_textViewFlags.delegateDidResignFirstResponder) [delegate textViewDidResignFirstResponder:self];
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
	return [^(TUIView *view, CGRect rect) {
		TUITextViewDrawRoundedFrame(view, 	floor(view.bounds.size.height / 2), NO);
	} copy];
}

TUIViewDrawRect TUITextViewSearchFrameOverDark(void)
{
	return [^(TUIView *view, CGRect rect) {
		TUITextViewDrawRoundedFrame(view, 	floor(view.bounds.size.height / 2), YES);
	} copy];
}
