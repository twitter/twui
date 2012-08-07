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

//	Portions of this code were taken from Velvet,
//	which is copyright (c) 2012 Bitswift, Inc.
//	See LICENSE.txt for more information.

#import "NSView+TUIExtensions.h"
#import "TUIHostView.h"
#import "TUIView.h"

/**
 * A view that is responsible for displaying and handling an NSView within the
 * normal TwUI view hierarchy.
 *
 * TUIViewNSViewContainer is powerful, but many of its interactions with AppKit rely upon
 * assumptions, magic, or unspecified behavior. To that end, there are several
 * restrictions on what you can do with TUIViewNSViewContainer:
 *
 * - A TUIViewNSViewContainer must always appear on top of TwUI views. A TUIViewNSViewContainer
 * should always appear at the end of a subview list. You should not attempt to
 * add TwUI subviews directly to a TUIViewNSViewContainer. Instead, if you need TwUI
 * views to appear on top, nest an TUINSView within the NSView and start
 * a new TwUI hierarchy.
 *
 * - You must not modify the geometry of the hosted NSView. If you need to
 * rearrange or resize the NSView, modify the TUIViewNSViewContainer and it will perform
 * the necessary updates.
 *
 * - You must not touch the layer of the hosted NSView. If you wish to
 * perform animations or apply other Core Animation effects, use the layer of
 * the TUIViewNSViewContainer. Note that not all Core Animation features may be available.
 *
 * - You should not subclass TUIViewNSViewContainer. If you need additional features,
 * create a new view class which contains a TUIViewNSViewContainer instead.
 */
@interface TUIViewNSViewContainer : TUIView <TUIHostView>

/**
 * Initializes the receiver, setting its rootView to the given view.
 *
 * The frame of the receiver will automatically be set to that of the given view.
 */
- (id)initWithNSView:(NSView *)view;

/**
 * The view displayed by the receiver.
 */
@property (nonatomic, strong) NSView *rootView;

@end
