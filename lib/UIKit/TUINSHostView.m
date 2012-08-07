//
//	TUINSHostView.m
//	TwUI
//
//	Created by Justin Spahr-Summers on 17.07.12.
//
//	Portions of this code were taken from Velvet,
//	which is copyright (c) 2012 Bitswift, Inc.
//	See LICENSE.txt for more information.
//

#import "TUINSHostView.h"

@interface TUINSHostView ()
/*
 * Configures all the necessary properties on the receiver. This is outside of
 * an initializer because NSView has no true designated initializer.
 */
- (void)setUp;
@end

@implementation TUINSHostView

#pragma mark Properties

- (TUINSView *)superview {
	return (TUINSView *)[super superview];
}

#pragma mark Lifecycle

- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (!self)
		return nil;

	[self setUp];
	return self;
}

- (id)initWithFrame:(NSRect)frame; {
	self = [super initWithFrame:frame];
	if (!self)
		return nil;

	[self setUp];
	return self;
}

- (void)setUp; {
	// set up layer hosting
	self.layer = [CALayer layer];
	self.wantsLayer = YES;
}

#pragma mark Rendering

- (BOOL)needsDisplay {
	// mark this view as needing display anytime the layer is
	return [super needsDisplay] || [self.layer needsDisplay];
}

#pragma mark Event Handling

- (NSView *)hitTest:(NSPoint)point {
	return nil;
}

@end
