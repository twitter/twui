//
//  TUINSHostView.h
//  TwUI
//
//  Created by Justin Spahr-Summers on 17.07.12.
//
//  Portions of this code were taken from Velvet,
//  which is copyright (c) 2012 Bitswift, Inc.
//  See LICENSE.txt for more information.
//

#import <Cocoa/Cocoa.h>

@class TUINSView;

/*
 * Private layer-hosted view class, containing the whole TwUI view hierarchy.
 * This class needs to be a subview of an TUINSView, because the latter is
 * layer-backed (not layer-hosted), in order to support a separate NSView
 * hierarchy.
 */
@interface TUINSHostView : NSView
- (TUINSView *)superview;
@end
