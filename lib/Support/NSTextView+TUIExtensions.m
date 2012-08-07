//
//	NSTextView+TUIExtensions.m
//
//	Created by Justin Spahr-Summers on 10.03.12.
//	Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "NSTextView+TUIExtensions.h"
#import <objc/runtime.h>

static void (*originalDrawRectIMP)(id, SEL, NSRect);

static void fixedDrawRect (NSTextView *self, SEL _cmd, NSRect rect) {
	CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;

	CGContextSetAllowsAntialiasing(context, YES);
	CGContextSetAllowsFontSmoothing(context, YES);
	CGContextSetAllowsFontSubpixelPositioning(context, YES);
	CGContextSetAllowsFontSubpixelQuantization(context, YES);

	// NSTextView likes to fall on non-integral points sometimes -- fix that
	if ([self.superview respondsToSelector:@selector(backingAlignedRect:options:)]) {
		self.frame = [self.superview backingAlignedRect:self.frame options:NSAlignAllEdgesNearest];
	} else {
		// This is less reliable, since one of our ancestors may not be on
		// integral points.
		self.frame = NSIntegralRect(self.frame);
	}

	originalDrawRectIMP(self, _cmd, rect);
}

@implementation NSTextView (TUIExtensions)

+ (void)load {
	Method drawRect = class_getInstanceMethod(self, @selector(drawRect:));
	originalDrawRectIMP = (void (*)(id, SEL, NSRect))method_getImplementation(drawRect);

	class_replaceMethod(self, method_getName(drawRect), (IMP)&fixedDrawRect, method_getTypeEncoding(drawRect));
}

@end
