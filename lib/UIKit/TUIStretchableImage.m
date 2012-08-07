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

#import "TUIStretchableImage.h"

@implementation TUIStretchableImage

#pragma mark Properties

@synthesize capInsets = _capInsets;

#pragma mark Drawing

- (void)drawInRect:(NSRect)dstRect fromRect:(NSRect)srcRect operation:(NSCompositingOperation)op fraction:(CGFloat)alpha {
	[self drawInRect:dstRect fromRect:srcRect operation:op fraction:alpha respectFlipped:YES hints:nil];
}

- (void)drawInRect:(NSRect)dstRect fromRect:(NSRect)srcRect operation:(NSCompositingOperation)op fraction:(CGFloat)alpha respectFlipped:(BOOL)respectFlipped hints:(NSDictionary *)hints {
	CGImageRef image = [self CGImageForProposedRect:&dstRect context:[NSGraphicsContext currentContext] hints:hints];
	if (image == NULL) {
		NSLog(@"*** Could not get CGImage of %@", self);
		return;
	}

	CGSize size = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
	TUIEdgeInsets insets = self.capInsets;

	// TODO: Cache the nine-part images for this common case of wanting to draw
	// the whole source image.
	if (CGRectIsEmpty(srcRect)) {
		// Match the image creation that occurs in the 'else' clause.
		CGImageRetain(image);
	} else {
		image = CGImageCreateWithImageInRect(image, srcRect);
		if (!image) return;

		// Reduce insets to account for taking only part of the original image.
		insets.left = fmax(0, insets.left - CGRectGetMinX(srcRect));
		insets.bottom = fmax(0, insets.bottom - CGRectGetMinY(srcRect));

		CGFloat srcRightInset = size.width - CGRectGetMaxX(srcRect);
		insets.right = fmax(0, insets.right - srcRightInset);

		CGFloat srcTopInset = size.height - CGRectGetMaxY(srcRect);
		insets.top = fmax(0, insets.top - srcTopInset);
	}

	NSImage *topLeft = nil, *topEdge = nil, *topRight = nil;
	NSImage *leftEdge = nil, *center = nil, *rightEdge = nil;
	NSImage *bottomLeft = nil, *bottomEdge = nil, *bottomRight = nil;

	// Length of sides that run vertically.
	CGFloat verticalEdgeLength = fmax(0, size.height - insets.top - insets.bottom);

	// Length of sides that run horizontally.
	CGFloat horizontalEdgeLength = fmax(0, size.width - insets.left - insets.right);

	NSImage *(^imageWithRect)(CGRect) = ^ id (CGRect rect){
		CGImageRef part = CGImageCreateWithImageInRect(image, rect);
		if (part == NULL) return nil;

		NSImage *image = [[NSImage alloc] initWithCGImage:part size:rect.size];
		CGImageRelease(part);

		return image;
	};

	if (verticalEdgeLength > 0) {
		if (insets.left > 0) {
			CGRect partRect = CGRectMake(0, insets.bottom, insets.left, verticalEdgeLength);
			leftEdge = imageWithRect(partRect);
		}

		if (insets.right > 0) {
			CGRect partRect = CGRectMake(size.width - insets.right, insets.bottom, insets.right, verticalEdgeLength);
			rightEdge = imageWithRect(partRect);
		}
	}

	if (horizontalEdgeLength > 0) {
		if (insets.bottom > 0) {
			CGRect partRect = CGRectMake(insets.left, 0, horizontalEdgeLength, insets.bottom);
			bottomEdge = imageWithRect(partRect);
		}

		if (insets.top > 0) {
			CGRect partRect = CGRectMake(insets.left, size.height - insets.top, horizontalEdgeLength, insets.top);
			topEdge = imageWithRect(partRect);
		}
	}

	if (insets.left > 0 && insets.top > 0) {
		CGRect partRect = CGRectMake(0, size.height - insets.top, insets.left, insets.top);
		topLeft = imageWithRect(partRect);
	}

	if (insets.left > 0 && insets.bottom > 0) {
		CGRect partRect = CGRectMake(0, 0, insets.left, insets.bottom);
		bottomLeft = imageWithRect(partRect);
	}

	if (insets.right > 0 && insets.top > 0) {
		CGRect partRect = CGRectMake(size.width - insets.right, size.height - insets.top, insets.right, insets.top);
		topRight = imageWithRect(partRect);
	}

	if (insets.right > 0 && insets.bottom > 0) {
		CGRect partRect = CGRectMake(size.width - insets.right, 0, insets.right, insets.bottom);
		bottomRight = imageWithRect(partRect);
	}

	CGRect centerRect = TUIEdgeInsetsInsetRect(CGRectMake(0, 0, size.width, size.height), insets);
	if (centerRect.size.width > 0 && centerRect.size.height > 0) {
		center = imageWithRect(centerRect);
	}

	CGImageRelease(image);

	BOOL flipped = NO;
	if (respectFlipped) {
		flipped = [[NSGraphicsContext currentContext] isFlipped];
	}

	if (topLeft != nil || bottomRight != nil) {
		NSDrawNinePartImage(dstRect, topLeft, topEdge, topRight, leftEdge, center, rightEdge, bottomLeft, bottomEdge, bottomRight, op, alpha, flipped);
	} else if (leftEdge != nil) {
		// Horizontal three-part image.
		NSDrawThreePartImage(dstRect, leftEdge, center, rightEdge, NO, op, alpha, flipped);
	} else {
		// Vertical three-part image.
		NSDrawThreePartImage(dstRect, topEdge, center, bottomEdge, YES, op, alpha, flipped);
	}
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	TUIStretchableImage *image = [super copyWithZone:zone];
	image.capInsets = self.capInsets;
	return image;
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self == nil) return nil;

	self.capInsets = TUIEdgeInsetsMake(
		[coder decodeFloatForKey:@"capInsetTop"],
		[coder decodeFloatForKey:@"capInsetLeft"],
		[coder decodeFloatForKey:@"capInsetBottom"],
		[coder decodeFloatForKey:@"capInsetRight"]
	);

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];

	[coder encodeFloat:self.capInsets.top forKey:@"capInsetTop"];
	[coder encodeFloat:self.capInsets.left forKey:@"capInsetLeft"];
	[coder encodeFloat:self.capInsets.bottom forKey:@"capInsetBottom"];
	[coder encodeFloat:self.capInsets.right forKey:@"capInsetRight"];
}

@end
