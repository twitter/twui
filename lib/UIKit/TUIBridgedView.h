//
//  TUIBridgedView.h
//  TwUI
//
//  Created by Justin Spahr-Summers on 17.07.12.
//
//  Portions of this code were taken from Velvet,
//  which is copyright (c) 2012 Bitswift, Inc.
//  See LICENSE.txt for more information.
//

#import <Foundation/Foundation.h>

@protocol TUIBridgedScrollView;
@protocol TUIHostView;
@class TUINSView;

/**
 * Represents a view that can be bridged by TwUI.
 *
 * Currently, only NSView and TUIView conform to this protocol.
 */
@protocol TUIBridgedView <NSObject>
@required

/**
 * Converts a point from the coordinate system of the window to that of the
 * receiver.
 */
- (CGPoint)convertFromWindowPoint:(CGPoint)point;

/**
 * Converts a point from the receiver's coordinate system to that of its window.
 */
- (CGPoint)convertToWindowPoint:(CGPoint)point;

/**
 * Converts a rectangle from the coordinate system of the window to that of the
 * receiver.
 */
- (CGRect)convertFromWindowRect:(CGRect)rect;

/**
 * Converts a rectangle from the receiver's coordinate system to that of its window.
 */
- (CGRect)convertToWindowRect:(CGRect)rect;

/**
 * The layer backing the receiver.
 *
 * This property must never be nil.
 */
@property (nonatomic, strong, readonly) CALayer *layer;

/**
 * The view directly or indirectly hosting the receiver, or nil if the
 * receiver is not part of a hosted view hierarchy.
 *
 * The receiver or one of its ancestors will be the [TUIHostView rootView] of
 * this view.
 *
 * Implementing classes may require that this property be of a more specific
 * type.
 *
 * This property should not be set except by the TUIHostView itself.
 */
@property (nonatomic, unsafe_unretained) id<TUIHostView> hostView;

/**
 * Returns the receiver's hostView or superview, whichever is closer in the
 * hierarchy.
 */
- (id<TUIBridgedView>)immediateParentView;

/**
 * Invoked any time an ancestor of the receiver has relaid itself out,
 * potentially moving or clipping the receiver relative to one of its ancestor
 * views.
 *
 * The receiver _must_ forward this message to all of its subviews and any
 * [TUIHostView rootView].
 */
- (void)ancestorDidLayout;

/**
 * Invoked any time the receiver has changed absolute positions in the view
 * hierarchy.
 *
 * This will include, for example, any time the receiver or one of its ancestors
 * changes superviews, changes host views, is reordered within its superview,
 * etc.
 *
 * The receiver _must_ forward this message to all of its subviews and any
 * [TUIHostView rootView].
 */
- (void)viewHierarchyDidChange;

/**
 * Returns the nearest <TUINSView> that is an ancestor of the receiver, or of
 * a view hosting the receiver.
 *
 * Returns nil if the receiver is not part of a TwUI-hosted view hierarchy.
 */
- (TUINSView *)ancestorTUINSView;

/**
 * Walks up the receiver's ancestor views, returning the nearest
 * <TUIBridgedScrollView>.
 *
 * Returns nil if no scroll view is an ancestor of the receiver.
 */
- (id<TUIBridgedScrollView>)ancestorScrollView;

/**
 * Invoked when the receiver is moving to a new <ancestorTUINSView>.
 *
 * 'view' will be nil if the receiver is being detached from its current
 * <ancestorTUINSView>.
 *
 * The receiver _must_ forward this message to all of its subviews and any
 * [TUIHostView rootView].
 */
- (void)willMoveToTUINSView:(TUINSView *)view;

/**
 * Invoked when the receiver has moved to a new <ancestorTUINSView>.
 *
 * 'view' will be nil if the receiver was previously not hosted.
 *
 * The receiver _must_ forward this message to all of its subviews and any
 * [TUIHostView rootView].
 */
- (void)didMoveFromTUINSView:(TUINSView *)view;

/**
 * Hit tests the receiver's view hierarchy, returning the <TUIBridgedView> which
 * is occupying the given point, or nil if there is no such view.
 *
 * This method should only traverse views which are visible and allow user
 * interaction.
 *
 * 'point' should be specified in the coordinate system of the receiver.
 */
- (id<TUIBridgedView>)descendantViewAtPoint:(CGPoint)point;

/**
 * Returns whether the receiver is occupying the given point.
 *
 * 'point' should be specified in the coordinate system of the receiver.
 */
- (BOOL)pointInside:(CGPoint)point;

@end
