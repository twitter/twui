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

#import <Cocoa/Cocoa.h>
#import "TUINSView.h"

// BASED ON THE INAppStoreWindow by indragiek, and
// the TUINSWindow that was used for Twitter for Mac.
// A combo pack that sets everything up for you!
// The implementation code shows how it's done.

// A general set of window additions to support
// any NSWindow housing a TUINSView to be able
// to use TUIViews instead of NSViews in them.
// It is recommended to use TUIWindows instead
// of generic NSWindows because of the in-built
// performance gains and flexibility, however.
@interface NSWindow (TUIWindowAdditions)

// Return the array of TUINSViews in the heirarchy.
- (NSArray *)TUINSViews;

// Set -setNeedsDisplay on all TUIView subviews.
- (void)setEverythingNeedsDisplay;

// Check if a responder exists in the chain. Note
// that this also applies to TUIResponder, as the
// TUIResponder is an NSResponder subclass.
- (BOOL)TUI_containsObjectInResponderChain:(NSResponder *)r;

// If you know you need to make something first 
// responder in the future (say, after an animation
// completes), but not if something is made first 
// responder in the meantime, use this:
// 
// 1. Request a token with futureMakeFirstResponderRequestToken.
// 2. When the animation completes, try to make first responder with:
// 			makeFirstResponder:withFutureRequestToken:
// 3. It will succeed if nothing else made something 
//    else first responder before you did.

// Increments future token and makes responder.
- (BOOL)TUI_makeFirstResponder:(NSResponder *)aResponder;

- (NSInteger)futureMakeFirstResponderRequestToken;
- (BOOL)makeFirstResponder:(NSResponder *)aResponder withFutureRequestToken:(NSInteger)token;
- (BOOL)makeFirstResponderIfNotAlreadyInResponderChain:(NSResponder *)responder;
- (BOOL)makeFirstResponderIfNotAlreadyInResponderChain:(NSResponder *)responder withFutureRequestToken:(NSInteger)token;

@end

// Draws a default style Mac OS X title bar.
@interface TUITitlebarView : NSView
@end

// A performance-optimized pre-built TUINSView
// heirarchial container window, which is still
// Cocoa compatible. Set the rootView to your
// TUIView of choice, and everything else is automatic.
@interface TUIWindow : NSWindow

// The height of the title bar. By default, this is set
// to the standard title bar height, 22px.
@property (nonatomic) CGFloat titleBarHeight;

// The title bar view itself. Add subviews to this view 
// that you want to show in the title bar (e.g. buttons, 
// a toolbar, etc.). This view can also be set if you 
// want to use a different styled title bar aside from
// the default one (textured, etc.).
@property (nonatomic, retain) NSView *titleBarView;

// Set whether the fullscreen or traffic light buttons are horizontally centered.
@property (nonatomic) BOOL centerFullScreenButton;
@property (nonatomic) BOOL centerTrafficLightButtons;

// Set whether you want the title bar to hide in fullscreen mode.
@property (nonatomic) BOOL hideTitleBarInFullScreen;

// Set whether the baseline TUIWindow draws between itself and the main window contents is shown.
@property (nonatomic) BOOL showsBaselineSeparator;

// Adjust the left and right padding of the trafficlight and fullscreen buttons.
@property (nonatomic) CGFloat trafficLightButtonsLeftMargin;
@property (nonatomic) CGFloat fullScreenButtonRightMargin;

// Get the container TUINSView or the set the root view TUIView.
@property (nonatomic, readonly) TUINSView *containerView;
@property (nonatomic, retain) TUIView *rootView;

// An overridable block to customize the TUIWindow's titlebar drawing.
typedef void (^TUIWindowTitleBarDrawingBlock)(BOOL drawsAsMainWindow,
                                             CGRect drawingRect,
                                             CGPathRef clippingPath);
@property (nonatomic, copy) TUIWindowTitleBarDrawingBlock titleBarDrawingBlock;

// Simpler initialization methods than those for the NSWindow.
- (id)initWithContentRect:(NSRect)contentRect;
- (id)initWithContentRect:(NSRect)contentRect screen:(NSScreen *)screen;
- (id)initBorderlessWithContentRect:(NSRect)contentRect;

@end
