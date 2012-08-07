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

@interface NSWindow (TUIWindowAdditions)

- (NSArray *)TUINSViews;
- (void)setEverythingNeedsDisplay;

- (BOOL)tui_containsObjectInResponderChain:(NSResponder *)r;

/*
 If you know you need to make something first responder in the future (say, after an animation completes),
 but not if something is made first responder in the meantime, use this:
 1. request a token with futureMakeFirstResponderRequestToken
 2. when the animation completes, try to make first responder with
 makeFirstResponder:withFutureRequestToken:
 3. it will succeed if nothing else made something else first responder before you did
 
 Currently used by TUITableView for when you're arrowing around really fast, and switch sections before
 the selected cell comes onscreen.
 
 Note this has only been tested with a NSWindow subclass that overrides -makeFirstResponder directly,
 not with a vanilla NSWindow since I started moving these methods into a category.
 */

- (BOOL)tui_makeFirstResponder:(NSResponder *)aResponder; // increments future token

- (NSInteger)futureMakeFirstResponderRequestToken;
- (BOOL)makeFirstResponder:(NSResponder *)aResponder withFutureRequestToken:(NSInteger)token;
- (BOOL)makeFirstResponderIfNotAlreadyInResponderChain:(NSResponder *)responder;
- (BOOL)makeFirstResponderIfNotAlreadyInResponderChain:(NSResponder *)responder withFutureRequestToken:(NSInteger)token;

@end

/*
 If you're not Twitter for Mac, you probably don't want to use TUINSWindow.
 Just use a plain NSWindow, this class will likely be removed from TUIKit
 once a bit of cleanup happens on Twitter for Mac. See the category above
 for stuff that you can use on any NSWindow instance.
 */

@interface TUINSWindow : NSWindow <NSWindowDelegate>
{
	TUINSView *nsView;
	NSMutableArray *altUINSViews; // kill
}

- (id)initWithContentRect:(CGRect)rect;

- (void)drawBackground:(CGRect)rect;

- (CGFloat)toolbarHeight;

@property (nonatomic, readonly) TUINSView *nsView;
@property (nonatomic, readonly) NSMutableArray *altUINSViews; // add to this to participate in setEverythingNeedsDisplay

@end

extern NSRect ABClampProposedRectToScreen(NSRect proposedRect);
