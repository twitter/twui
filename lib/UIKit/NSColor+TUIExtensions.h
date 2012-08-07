//
//  NSColor+TUIExtensions.h
//
//  Created by Justin Spahr-Summers on 01.12.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import <AppKit/AppKit.h>

/*
 * Extensions to NSColor that add interoperability with CGColor.
 */
@interface NSColor (TUIExtensions)

/*
 * The CGColor corresponding to the receiver.
 */
@property (nonatomic, readonly) CGColorRef tui_CGColor;

/*
 * Returns an NSColor corresponding to the given CGColor.
 *
 * This method will not handle pattern colors.
 */
+ (NSColor *)tui_colorWithCGColor:(CGColorRef)color;

@end
