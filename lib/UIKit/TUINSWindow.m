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

#import "TUIWindow.h"
#import "TUIKit.h"

#define TUI_COMPILING_LION __MAC_OS_X_VERSION_MAX_ALLOWED >= 1070

/** -----------------------------------------
 - There are 2 sets of colors, one for an active (key) state and one for an inactivate state
 - Each set contains 3 colors. 2 colors for the start and end of the title gradient, and another color to draw the separator line on the bottom
 - These colors are meant to mimic the color of the default titlebar (taken from OS X 10.6), but are subject
 to change at any time
 ----------------------------------------- **/

#define TUI_COLOR_KEY_START 		 [NSColor colorWithDeviceWhite:0.659 alpha:1.0]
#define TUI_COLOR_KEY_END 		 [NSColor colorWithDeviceWhite:0.812 alpha:1.0]
#define TUI_COLOR_KEY_BOTTOM 	 [NSColor colorWithDeviceWhite:0.318 alpha:1.0]

#define TUI_COLOR_NOTKEY_START 	 [NSColor colorWithDeviceWhite:0.851 alpha:1.0]
#define TUI_COLOR_NOTKEY_END 	 [NSColor colorWithDeviceWhite:0.929 alpha:1.0]
#define TUI_COLOR_NOTKEY_BOTTOM 	 [NSColor colorWithDeviceWhite:0.600 alpha:1.0]

/** Lion */

#define TUI_COLOR_KEY_START_L 	 [NSColor colorWithDeviceWhite:0.66 alpha:1.0]
#define TUI_COLOR_KEY_END_L 		 [NSColor colorWithDeviceWhite:0.9 alpha:1.0]
#define TUI_COLOR_KEY_BOTTOM_L 	 [NSColor colorWithDeviceWhite:0.408 alpha:1.0]

#define TUI_COLOR_NOTKEY_START_L  [NSColor colorWithDeviceWhite:0.878 alpha:1.0]
#define TUI_COLOR_NOTKEY_END_L 	 [NSColor colorWithDeviceWhite:0.976 alpha:1.0]
#define TUI_COLOR_NOTKEY_BOTTOM_L [NSColor colorWithDeviceWhite:0.655 alpha:1.0]

/** Corner clipping radius **/
#if TUI_COMPILING_MOUNTAIN
const CGFloat INCornerClipRadius = 6.0;
#else
const CGFloat INCornerClipRadius = 4.0;
#endif

const CGFloat INButtonTopOffset = 3.0;

NS_INLINE CGFloat INMidHeight(NSRect aRect){
    return (aRect.size.height * (CGFloat)0.5);
}

static inline CGImageRef createNoiseImageRef(NSUInteger width, NSUInteger height, CGFloat factor)
{
    NSUInteger size = width*height;
    char *rgba = (char *)malloc(size); srand(124);
    for(NSUInteger i=0; i < size; ++i){rgba[i] = rand()%256*factor;}
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapContext = 
    CGBitmapContextCreate(rgba, width, height, 8, width, colorSpace, kCGImageAlphaNone);
    free(rgba);
    CGColorSpaceRelease(colorSpace);
    CGImageRef image = CGBitmapContextCreateImage(bitmapContext);
    CFRelease(bitmapContext);
    return image;
}

static inline CGPathRef createClippingPathWithRectAndRadius(NSRect rect, CGFloat radius)
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, NSMinX(rect), NSMinY(rect));
    CGPathAddLineToPoint(path, NULL, NSMinX(rect), NSMaxY(rect)-radius);
    CGPathAddArcToPoint(path, NULL, NSMinX(rect), NSMaxY(rect), NSMinX(rect)+radius, NSMaxY(rect), radius);
    CGPathAddLineToPoint(path, NULL, NSMaxX(rect)-radius, NSMaxY(rect));
    CGPathAddArcToPoint(path, NULL,  NSMaxX(rect), NSMaxY(rect), NSMaxX(rect), NSMaxY(rect)-radius, radius);
    CGPathAddLineToPoint(path, NULL, NSMaxX(rect), NSMinY(rect));
    CGPathCloseSubpath(path);
    return path;
}

static inline CGGradientRef createGradientWithColors(NSColor *startingColor, NSColor *endingColor)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGFloat startingComponents[2];
    [startingColor getWhite:&startingComponents[0] alpha:&startingComponents[1]];
    
    CGFloat endingComponents[2];
    [endingColor getWhite:&endingComponents[0] alpha:&endingComponents[1]];
    
    CGFloat compontents[4] = {
        startingComponents[0],
        startingComponents[1],
        endingComponents[0],
        endingComponents[1],
    };
    
    CGFloat locations[2] = {
        0.0f,
        1.0f,
    };
    
    CGGradientRef gradient = 
    CGGradientCreateWithColorComponents(colorSpace, 
                                        (const CGFloat *)&compontents, 
                                        (const CGFloat *)&locations, 2);
    CGColorSpaceRelease(colorSpace);
    return gradient;
}

@interface NSView (TUIWindowAdditions)
@end
@implementation NSView (TUIWindowAdditions)

- (void)findViewsOfClass:(Class)cls addTo:(NSMutableArray *)array
{
	if([self isKindOfClass:cls])
		[array addObject:self];
	for(NSView *v in [self subviews])
		[v findViewsOfClass:cls addTo:array];
}

@end

@implementation NSWindow (TUIWindowAdditions)

- (NSArray *)TUINSViews
{
	NSMutableArray *array = [NSMutableArray array];
	[[self contentView] findViewsOfClass:[TUINSView class] addTo:array];
	return array;
}

- (void)setEverythingNeedsDisplay
{
	[[self contentView] setNeedsDisplay:YES];
	[[self TUINSViews] makeObjectsPerformSelector:@selector(setEverythingNeedsDisplay)];
}

NSInteger makeFirstResponderCount = 0;

- (BOOL)TUI_containsObjectInResponderChain:(NSResponder *)r
{
	NSResponder *responder = [self firstResponder];
	do {
		if(r == responder)
			return YES;
	} while((responder = [responder nextResponder]));
	return NO;
}

- (NSInteger)futureMakeFirstResponderRequestToken
{
	return makeFirstResponderCount;
}

- (BOOL)TUI_makeFirstResponder:(NSResponder *)aResponder
{
	++makeFirstResponderCount; // cool if it overflows
	if([aResponder respondsToSelector:@selector(initialFirstResponder)])
		aResponder = ((TUIResponder *)aResponder).initialFirstResponder;
	return [self makeFirstResponder:aResponder];
}

- (BOOL)makeFirstResponder:(NSResponder *)aResponder withFutureRequestToken:(NSInteger)token
{
	if(token == makeFirstResponderCount) {
		return [self TUI_makeFirstResponder:aResponder];
	} else {
		return NO;
	}
}

- (BOOL)makeFirstResponderIfNotAlreadyInResponderChain:(NSResponder *)responder
{
	if(![self TUI_containsObjectInResponderChain:responder])
		return [self TUI_makeFirstResponder:responder];
	return NO;
}

- (BOOL)makeFirstResponderIfNotAlreadyInResponderChain:(NSResponder *)responder withFutureRequestToken:(NSInteger)token
{
	if(![self TUI_containsObjectInResponderChain:responder])
		return [self makeFirstResponder:responder withFutureRequestToken:token];
	return NO;
}


@end

@interface TUIWindowDelegateProxy : NSObject <NSWindowDelegate>
@property (nonatomic, assign) id<NSWindowDelegate> secondaryDelegate;
@end

@implementation TUIWindowDelegateProxy
@synthesize secondaryDelegate = _secondaryDelegate;

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if ([_secondaryDelegate respondsToSelector:[anInvocation selector]]) {
        [anInvocation invokeWithTarget:_secondaryDelegate];
    } else {
        [super forwardInvocation:anInvocation];
    }
}

- (NSRect)window:(TUIWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect
{
    rect.origin.y = NSHeight(window.frame)-window.titleBarHeight;
    return rect;
}
@end

@interface TUIWindow ()
- (void)_doInitialWindowSetup;
- (void)_createTitlebarView;
- (void)_setupTrafficLightsTrackingArea;
- (void)_recalculateFrameForTitleBarView;
- (void)_layoutTrafficLightsAndContent;
- (CGFloat)_minimumTitlebarHeight;
- (void)_displayWindowAndTitlebar;
- (void)_hideTitleBarView:(BOOL)hidden;
- (CGFloat)_defaultTrafficLightLeftMargin;
- (CGFloat)_trafficLightSeparation;
- (void)drawBackground:(CGRect)rect;
- (void)setupWindow:(CGRect)rect;
- (void)blurWindowBackground;
@end

@interface TUIWindowFrame : NSView {
@package
	TUIWindow *w;
}

@end

@implementation TUIWindowFrame

- (void)drawRect:(CGRect)r {
	[w drawBackground:r];
}

@end

@implementation TUITitlebarView {
    BOOL shouldMiniaturize;
}

- (id)initWithFrame:(NSRect)frameRect {
    if((self = [super initWithFrame:frameRect])) {
        // Get settings from "System Preferences" >  "Appearance" > "Double-click on windows title bar to minimize".
        [[NSUserDefaults standardUserDefaults] addSuiteNamed:NSGlobalDomain];
        shouldMiniaturize = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleMiniaturizeOnDoubleClick"] boolValue];
    } return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    TUIWindow *window = (TUIWindow *)[self window];
    BOOL drawsAsMainWindow = ([window isMainWindow] && [[NSApplication sharedApplication] isActive]);
    
    NSRect drawingRect = [self bounds];
    if ( window.titleBarDrawingBlock ) {
        CGPathRef clippingPath = createClippingPathWithRectAndRadius(drawingRect, INCornerClipRadius);
        window.titleBarDrawingBlock(drawsAsMainWindow, NSRectToCGRect(drawingRect), clippingPath);
        CGPathRelease(clippingPath);
    } else {
        CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];        
        
        NSColor *startColor = nil;
        NSColor *endColor = nil;
        if (isAtleastLion()) {
            startColor = drawsAsMainWindow ? TUI_COLOR_KEY_START_L : TUI_COLOR_NOTKEY_START_L;
            endColor = drawsAsMainWindow ? TUI_COLOR_KEY_END_L : TUI_COLOR_NOTKEY_END_L;
        } else {
            startColor = drawsAsMainWindow ? TUI_COLOR_KEY_START : TUI_COLOR_NOTKEY_START;
            endColor = drawsAsMainWindow ? TUI_COLOR_KEY_END : TUI_COLOR_NOTKEY_END;
        }
        
        NSRect clippingRect = drawingRect;
#if TUI_COMPILING_LION
        if((([window styleMask] & NSFullScreenWindowMask) == NSFullScreenWindowMask)){
            [[NSColor blackColor] setFill];
            [[NSBezierPath bezierPathWithRect:self.bounds] fill];
        }
#endif
        clippingRect.size.height -= 1;        
        CGPathRef clippingPath = createClippingPathWithRectAndRadius(clippingRect, INCornerClipRadius);
        CGContextAddPath(context, clippingPath);
        CGContextClip(context);
        CGPathRelease(clippingPath);
        
        CGGradientRef gradient = createGradientWithColors(startColor, endColor);
        CGContextDrawLinearGradient(context, gradient, CGPointMake(NSMidX(drawingRect), NSMinY(drawingRect)), 
                                    CGPointMake(NSMidX(drawingRect), NSMaxY(drawingRect)), 0);
        CGGradientRelease(gradient);
        
        if ([window showsBaselineSeparator]) {
            NSColor *bottomColor = nil;
            if (isAtleastLion()) {
                bottomColor = drawsAsMainWindow ? TUI_COLOR_KEY_BOTTOM_L : TUI_COLOR_NOTKEY_BOTTOM_L;
            } else {
                bottomColor = drawsAsMainWindow ? TUI_COLOR_KEY_BOTTOM : TUI_COLOR_NOTKEY_BOTTOM;
            }
            
            NSRect bottomRect = NSMakeRect(0.0, NSMinY(drawingRect), NSWidth(drawingRect), 1.0);
            [bottomColor set];
            NSRectFill(bottomRect);
            
            if (isAtleastLion()) {
                bottomRect.origin.y += 1.0;
                [[NSColor colorWithDeviceWhite:1.0 alpha:0.12] setFill];
                [[NSBezierPath bezierPathWithRect:bottomRect] fill];
            }
        }
        
        if (isAtleastLion() && drawsAsMainWindow) {
            static CGImageRef noisePattern = nil;
            if (noisePattern == nil) {
                noisePattern = createNoiseImageRef(128, 128, 0.015);
            }
            
            CGPathRef noiseClippingPath = 
            createClippingPathWithRectAndRadius(NSInsetRect(drawingRect, 1, 1), INCornerClipRadius);
            CGContextAddPath(context, noiseClippingPath);
            CGContextClip(context);
            CGPathRelease(noiseClippingPath);
            
            CGContextSetBlendMode(context, kCGBlendModePlusLighter);
            CGRect noisePatternRect = CGRectZero;
            noisePatternRect.size = CGSizeMake(CGImageGetWidth(noisePattern), CGImageGetHeight(noisePattern)); 
            CGContextDrawTiledImage(context, noisePatternRect, noisePattern);
        }        
    }
}

- (void)mouseUp:(NSEvent *)theEvent  {
    if ([theEvent clickCount] == 2 && shouldMiniaturize)
        [[self window] miniaturize:self];
}

@end

@implementation TUIWindow {
    CGFloat _cachedTitleBarHeight;  
    BOOL _setFullScreenButtonRightMargin;
    TUIWindowDelegateProxy *_delegateProxy;
}

@synthesize titleBarView = _titleBarView;
@synthesize titleBarHeight = _titleBarHeight;
@synthesize centerFullScreenButton = _centerFullScreenButton;
@synthesize centerTrafficLightButtons = _centerTrafficLightButtons;
@synthesize hideTitleBarInFullScreen = _hideTitleBarInFullScreen;
@synthesize titleBarDrawingBlock = _titleBarDrawingBlock;
@synthesize showsBaselineSeparator = _showsBaselineSeparator;
@synthesize fullScreenButtonRightMargin = _fullScreenButtonRightMargin;
@synthesize trafficLightButtonsLeftMargin = _trafficLightButtonsLeftMargin;

@synthesize rootView = _rootView;
@synthesize containerView = _containerView;

#pragma mark -
#pragma mark Internal Properties

- (BOOL)useCustomContentView {
	return NO;
}

#pragma mark -
#pragma mark Initialization

- (void)setupWindow:(CGRect)rect {
    [self _doInitialWindowSetup];
    
    [self setReleasedWhenClosed:NO];
    [self setCollectionBehavior:NSWindowCollectionBehaviorParticipatesInCycle | NSWindowCollectionBehaviorManaged];
    [self setAcceptsMouseMovedEvents:YES];
    
    CGRect containerRect = rect;
    containerRect.size.height -= (self.titleBarHeight - 22);
    _containerView = [[TUINSView alloc] initWithFrame:containerRect];
    [_containerView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
    if([self useCustomContentView]) {
        [self setOpaque:NO];
        [_containerView TUI_setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [self setHasShadow:YES];
        
        TUIWindowFrame *contentView = [[TUIWindowFrame alloc] initWithFrame:rect];
        contentView->w = self;
        [self setContentView:contentView];
        [[self contentView] addSubview:_containerView];
    } else {
        [self setOpaque:YES];
        [self setHasShadow:YES];
        [self setContentView:_containerView];
        [self setBackgroundColor:[NSColor clearColor]];
    }
}

- (id)initBorderlessWithContentRect:(NSRect)contentRect {
    if((self = [self initWithContentRect:contentRect  
                               styleMask:NSBorderlessWindowMask 
                                 backing:NSBackingStoreBuffered 
                                   defer:NO])) {
        [self setOpaque:NO];
        [_containerView TUI_setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [self _hideTitleBarView:YES];
    } return self;
}

- (id)initWithContentRect:(NSRect)contentRect {
    return [self initWithContentRect:contentRect  
                           styleMask:NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask 
                             backing:NSBackingStoreBuffered 
                               defer:NO];
}

- (id)initWithContentRect:(NSRect)contentRect screen:(NSScreen *)screen {
    return [self initWithContentRect:contentRect  
                           styleMask:NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask 
                             backing:NSBackingStoreBuffered 
                               defer:NO
                              screen:screen];
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
    if((self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag]))
        [self setupWindow:contentRect];
    return self;
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag screen:(NSScreen *)screen {
    if((self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag screen:screen]))
        [self setupWindow:contentRect];
    return self;
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setDelegate:nil];
    [_delegateProxy release];
    [_titleBarView release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark NSWindow Overrides

- (void)becomeKeyWindow {
    [super becomeKeyWindow];
	[self setEverythingNeedsDisplay];
    [_titleBarView setNeedsDisplay:YES];
}

- (void)resignKeyWindow {
    [super resignKeyWindow];
	[_containerView endHyperFocus:YES];
	[self setEverythingNeedsDisplay];
    [_titleBarView setNeedsDisplay:YES];
}

- (void)becomeMainWindow {
    [super becomeMainWindow];
	[self setEverythingNeedsDisplay];
    [_titleBarView setNeedsDisplay:YES];   
}

- (void)resignMainWindow {
    [super resignMainWindow];
	[_containerView endHyperFocus:YES];
	[self setEverythingNeedsDisplay];
    [_titleBarView setNeedsDisplay:YES];  
}

- (BOOL)canBecomeKeyWindow {
	return YES;
}

- (BOOL)canBecomeMainWindow {
    return ![self.titleBarView isHidden];
}

#pragma mark -
#pragma mark Accessors

- (void)setRootView:(TUIView *)aView {
    if(_rootView != aView) {
        if(_rootView != nil) {
            [_rootView release];
        } _rootView = nil;
        
        _rootView = [aView retain];
        [_containerView setRootView:_rootView];
    }
}

- (TUIView *)rootView {
    return _rootView;
}

- (void)setTitleBarView:(NSView *)newTitleBarView {
    if ((_titleBarView != newTitleBarView) && newTitleBarView && (!(self.styleMask & NSBorderlessWindowMask))) {
        [_titleBarView removeFromSuperview];
        [_titleBarView release];
        _titleBarView = [newTitleBarView retain];
        
        // Configure the view properties and add it as a subview of the theme frame
        NSView *themeFrame = [[self contentView] superview];
        NSView *firstSubview = [[themeFrame subviews] objectAtIndex:0];
        [_titleBarView setAutoresizingMask:(NSViewMinYMargin | NSViewWidthSizable)];
        [self _recalculateFrameForTitleBarView];
        [themeFrame addSubview:_titleBarView positioned:NSWindowBelow relativeTo:firstSubview];
        [self _layoutTrafficLightsAndContent];
        [self _displayWindowAndTitlebar];
    }
}

- (NSView *)titleBarView
{
    return _titleBarView;
}

- (void)setTitleBarHeight:(CGFloat)newTitleBarHeight 
{
	if (_titleBarHeight != newTitleBarHeight) {
        _cachedTitleBarHeight = MAX(22, newTitleBarHeight);
		_titleBarHeight = _cachedTitleBarHeight;
		[self _recalculateFrameForTitleBarView];
		[self _layoutTrafficLightsAndContent];
		[self _displayWindowAndTitlebar];
	}
}

- (CGFloat)titleBarHeight
{
    return _titleBarHeight;
}

- (void)setShowsBaselineSeparator:(BOOL)showsBaselineSeparator
{
    if (_showsBaselineSeparator != showsBaselineSeparator) {
        _showsBaselineSeparator = showsBaselineSeparator;
            [self.titleBarView setNeedsDisplay:YES];
    }
}

- (BOOL)showsBaselineSeparator
{
    return _showsBaselineSeparator;
}

- (void)setTrafficLightButtonsLeftMargin:(CGFloat)newTrafficLightButtonsLeftMargin
{
	if (_trafficLightButtonsLeftMargin != newTrafficLightButtonsLeftMargin) {
		_trafficLightButtonsLeftMargin = newTrafficLightButtonsLeftMargin;
		[self _recalculateFrameForTitleBarView];
		[self _layoutTrafficLightsAndContent];
		[self _displayWindowAndTitlebar];
        [self _setupTrafficLightsTrackingArea];
	}
}

- (CGFloat)trafficLightButtonsLeftMargin
{
    return _trafficLightButtonsLeftMargin;
}


- (void)setFullScreenButtonRightMargin:(CGFloat)newFullScreenButtonRightMargin
{
	if (_fullScreenButtonRightMargin != newFullScreenButtonRightMargin) {
        _setFullScreenButtonRightMargin = YES;
		_fullScreenButtonRightMargin = newFullScreenButtonRightMargin;
		[self _recalculateFrameForTitleBarView];
		[self _layoutTrafficLightsAndContent];
		[self _displayWindowAndTitlebar];
	}
}

- (CGFloat)fullScreenButtonRightMargin
{
    return _fullScreenButtonRightMargin;
}

- (void)setCenterFullScreenButton:(BOOL)centerFullScreenButton{
    if( _centerFullScreenButton != centerFullScreenButton ) {
        _centerFullScreenButton = centerFullScreenButton;
        [self _layoutTrafficLightsAndContent];
    }
}

- (void)setCenterTrafficLightButtons:(BOOL)centerTrafficLightButtons
{
    if ( _centerTrafficLightButtons != centerTrafficLightButtons ) {
        _centerTrafficLightButtons = centerTrafficLightButtons;
        [self _layoutTrafficLightsAndContent];
        [self _setupTrafficLightsTrackingArea];
    }
}

- (void)setDelegate:(id<NSWindowDelegate>)anObject
{
    [_delegateProxy setSecondaryDelegate:anObject];
}

- (id<NSWindowDelegate>)delegate
{
    return [_delegateProxy secondaryDelegate];
}

- (void)drawBackground:(CGRect)rect
{
	// overridden by subclasses
	CGContextRef ctx = TUIGraphicsGetCurrentContext();
	CGRect f = [self frame];
	CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
	CGContextFillRect(ctx, f);
}

- (void)center {
	[self setFrame:NSOffsetRect(self.frame, NSMidX(self.screen.visibleFrame) - NSMidX(self.frame), 
                                			NSMidY(self.screen.visibleFrame) - NSMidY(self.frame)) 
           display:YES];
}

#pragma mark -
#pragma mark Private

- (void)_doInitialWindowSetup
{
    _showsBaselineSeparator = YES;
    _centerTrafficLightButtons = YES;
    _titleBarHeight = [self _minimumTitlebarHeight];
	_trafficLightButtonsLeftMargin = [self _defaultTrafficLightLeftMargin];
    [self setMovableByWindowBackground:YES];
    _delegateProxy = [[TUIWindowDelegateProxy alloc] init];
    [super setDelegate:_delegateProxy];
    
    /** -----------------------------------------
     - The window automatically does layout every time its moved or resized, which means that the traffic lights and content view get reset at the original positions, so we need to put them back in place
     - NSWindow is hardcoded to redraw the traffic lights in a specific rect, so when they are moved down, only part of the buttons get redrawn, causing graphical artifacts. Therefore, the window must be force redrawn every time it becomes key/resigns key
     ----------------------------------------- **/
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(_layoutTrafficLightsAndContent) name:NSWindowDidResizeNotification object:self];
    [nc addObserver:self selector:@selector(_layoutTrafficLightsAndContent) name:NSWindowDidMoveNotification object:self];
    [nc addObserver:self selector:@selector(_displayWindowAndTitlebar) name:NSWindowDidResignKeyNotification object:self];
    [nc addObserver:self selector:@selector(_displayWindowAndTitlebar) name:NSWindowDidBecomeKeyNotification object:self];
    [nc addObserver:self selector:@selector(_setupTrafficLightsTrackingArea) name:NSWindowDidBecomeKeyNotification object:self];
    [nc addObserver:self selector:@selector(_displayWindowAndTitlebar) name:NSApplicationDidBecomeActiveNotification object:nil];
    [nc addObserver:self selector:@selector(_displayWindowAndTitlebar) name:NSApplicationDidResignActiveNotification object:nil];
#if TUI_COMPILING_LION
    if (isAtleastLion()) {
        [nc addObserver:self selector:@selector(_setupTrafficLightsTrackingArea) name:NSWindowDidExitFullScreenNotification object:nil];
        [nc addObserver:self selector:@selector(windowWillEnterFullScreen:) name:NSWindowWillEnterFullScreenNotification object:nil];
        [nc addObserver:self selector:@selector(windowWillExitFullScreen:) name:NSWindowWillExitFullScreenNotification object:nil];
    }
#endif
    [self _createTitlebarView];
    [self _layoutTrafficLightsAndContent];
    [self _setupTrafficLightsTrackingArea];
}

- (void)_layoutTrafficLightsAndContent
{
    NSButton *close = [self standardWindowButton:NSWindowCloseButton];
    NSButton *minimize = [self standardWindowButton:NSWindowMiniaturizeButton];
    NSButton *zoom = [self standardWindowButton:NSWindowZoomButton];
    
    // Set the frame of the window buttons
    NSRect closeFrame = [close frame];
    NSRect minimizeFrame = [minimize frame];
    NSRect zoomFrame = [zoom frame];
    NSRect titleBarFrame = [_titleBarView frame];
    CGFloat buttonOrigin = 0.0;
    if ( self.centerTrafficLightButtons ) {
        buttonOrigin = round(NSMidY(titleBarFrame) - INMidHeight(closeFrame));
    } else {
        buttonOrigin = NSMaxY(titleBarFrame) - NSHeight(closeFrame) - INButtonTopOffset;
    }
    closeFrame.origin.y = buttonOrigin;
    minimizeFrame.origin.y = buttonOrigin;
    zoomFrame.origin.y = buttonOrigin;
	closeFrame.origin.x = _trafficLightButtonsLeftMargin;
    minimizeFrame.origin.x = _trafficLightButtonsLeftMargin + [self _trafficLightSeparation];
    zoomFrame.origin.x = _trafficLightButtonsLeftMargin + [self _trafficLightSeparation] * 2;
    [close setFrame:closeFrame];
    [minimize setFrame:minimizeFrame];
    [zoom setFrame:zoomFrame];
    
#if TUI_COMPILING_LION
    // Set the frame of the FullScreen button in Lion if available
    if ( isAtleastLion() ) {
        NSButton *fullScreen = [self standardWindowButton:NSWindowFullScreenButton];        
        if( fullScreen ) {
            NSRect fullScreenFrame = [fullScreen frame];
            if ( !_setFullScreenButtonRightMargin ) {
                self.fullScreenButtonRightMargin = NSWidth([_titleBarView frame]) - NSMaxX(fullScreen.frame);
            }
			fullScreenFrame.origin.x = NSWidth(titleBarFrame) - NSWidth(fullScreenFrame) - _fullScreenButtonRightMargin;
            if( self.centerFullScreenButton ) {
                fullScreenFrame.origin.y = round(NSMidY(titleBarFrame) - INMidHeight(fullScreenFrame));
            } else {
                fullScreenFrame.origin.y = NSMaxY(titleBarFrame) - NSHeight(fullScreenFrame) - INButtonTopOffset;
            }
            [fullScreen setFrame:fullScreenFrame];
        }
    }
#endif
    
    // Reposition the content view
    NSView *contentView = [self contentView];    
    NSRect windowFrame = [self frame];
    NSRect newFrame = [contentView frame];
    CGFloat titleHeight = NSHeight(windowFrame) - NSHeight(newFrame);
    CGFloat extraHeight = _titleBarHeight - titleHeight;
    newFrame.size.height -= extraHeight;
    [contentView setFrame:newFrame];
    [contentView setNeedsDisplay:YES];
}

- (void)windowWillEnterFullScreen:(NSNotification *)notification 
{
    if (_hideTitleBarInFullScreen) {
        // Recalculate the views when entering from fullscreen
        _titleBarHeight = 0.0f;
		[self _recalculateFrameForTitleBarView];
		[self _layoutTrafficLightsAndContent];
		[self _displayWindowAndTitlebar];
        
        [self _hideTitleBarView:YES];
    }
}

- (void)windowWillExitFullScreen:(NSNotification *)notification 
{
    if (_hideTitleBarInFullScreen) {
        _titleBarHeight = _cachedTitleBarHeight;
		[self _recalculateFrameForTitleBarView];
		[self _layoutTrafficLightsAndContent];
		[self _displayWindowAndTitlebar];
        
        [self _hideTitleBarView:NO];
    }
}

- (void)_createTitlebarView
{
    // Create the title bar view
    self.titleBarView = [[[TUITitlebarView alloc] initWithFrame:NSZeroRect] autorelease];
}

- (void)_hideTitleBarView:(BOOL)hidden 
{
    [self.titleBarView setHidden:hidden];
}

- (void)_setupTrafficLightsTrackingArea
{
    [[[self contentView] superview] viewWillStartLiveResize];
    [[[self contentView] superview] viewDidEndLiveResize];
}

- (void)_recalculateFrameForTitleBarView
{
    NSView *themeFrame = [[self contentView] superview];
    NSRect themeFrameRect = [themeFrame frame];
    NSRect titleFrame = NSMakeRect(0.0, NSMaxY(themeFrameRect) - _titleBarHeight, NSWidth(themeFrameRect), _titleBarHeight);
    [_titleBarView setFrame:titleFrame];
}

- (CGFloat)_minimumTitlebarHeight
{
    static CGFloat minTitleHeight = 0.0;
    if ( !minTitleHeight ) {
        NSRect frameRect = [self frame];
        NSRect contentRect = [self contentRectForFrameRect:frameRect];
        minTitleHeight = NSHeight(frameRect) - NSHeight(contentRect);
    }
    return minTitleHeight;
}

- (CGFloat)_defaultTrafficLightLeftMargin
{
    static CGFloat trafficLightLeftMargin = 0.0;
    if ( !trafficLightLeftMargin ) {
        NSButton *close = [self standardWindowButton:NSWindowCloseButton];
        trafficLightLeftMargin = NSMinX(close.frame);
    }
    return trafficLightLeftMargin;
}

- (CGFloat)_trafficLightSeparation
{
    static CGFloat trafficLightSeparation = 0.0;
    if ( !trafficLightSeparation ) {
        NSButton *close = [self standardWindowButton:NSWindowCloseButton];
        NSButton *minimize = [self standardWindowButton:NSWindowMiniaturizeButton];
        trafficLightSeparation = NSMinX(minimize.frame) - NSMinX(close.frame);
    }
    return trafficLightSeparation;    
}

- (void)_displayWindowAndTitlebar
{
    // Redraw the window and titlebar
    [_titleBarView setNeedsDisplay:YES];
}

@end

static NSScreen *TUIScreenForProposedWindowRect(NSRect proposedRect)
{
	NSScreen *screen = [NSScreen mainScreen];
	
	NSPoint center = NSMakePoint(proposedRect.origin.x + proposedRect.size.width * 0.5, proposedRect.origin.y + proposedRect.size.height * 0.5);
	for(NSScreen *s in [NSScreen screens]) {
		NSRect r = [s visibleFrame];
		if(NSPointInRect(center, r))
			screen = s;
	}
	
	return screen;
}

static NSRect TUIClampProposedRectToScreen(NSRect proposedRect)
{
	NSScreen *screen = TUIScreenForProposedWindowRect(proposedRect);
	NSRect screenRect = [screen visibleFrame];
    
	if(proposedRect.origin.y < screenRect.origin.y) {
		proposedRect.origin.y = screenRect.origin.y;
	}
    
	if(proposedRect.origin.y + proposedRect.size.height > screenRect.origin.y + screenRect.size.height) {
		proposedRect.origin.y = screenRect.origin.y + screenRect.size.height - proposedRect.size.height;
	}
    
	if(proposedRect.origin.x + proposedRect.size.width > screenRect.origin.x + screenRect.size.width) {
		proposedRect.origin.x = screenRect.origin.x + screenRect.size.width - proposedRect.size.width;
	}
    
	if(proposedRect.origin.x < screenRect.origin.x) {
		proposedRect.origin.x = screenRect.origin.x;
	}
    
	return proposedRect;
}