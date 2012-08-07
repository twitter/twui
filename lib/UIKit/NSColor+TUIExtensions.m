//
//  NSColor+TUIExtensions.m
//
//  Created by Justin Spahr-Summers on 01.12.11.
//  Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "NSColor+TUIExtensions.h"
#import "NSImage+TUIExtensions.h"

// CGPatterns involve some complex memory management which doesn't mesh well
// with ARC.
#if __has_feature(objc_arc)
#error "This file cannot be compiled with ARC."
#endif

static void drawCGImagePattern (void *info, CGContextRef context) {
    CGImageRef image = info;

    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
}

static void releasePatternInfo (void *info) {
    CFRelease(info);
}

@implementation NSColor (TUIExtensions)

+ (NSColor *)tui_colorWithCGColor:(CGColorRef)color; {
    if (!color)
        return nil;

    CGColorSpaceRef colorSpaceRef = CGColorGetColorSpace(color);

    NSColorSpace *colorSpace = [[NSColorSpace alloc] initWithCGColorSpace:colorSpaceRef];
    NSColor *result = [self colorWithColorSpace:colorSpace components:CGColorGetComponents(color) count:(size_t)CGColorGetNumberOfComponents(color)];
    [colorSpace release];

    return result;
}

- (CGColorRef)tui_CGColor; {
    if ([self.colorSpaceName isEqualToString:NSPatternColorSpace]) {
        CGImageRef patternImage = self.patternImage.tui_CGImage;
        if (!patternImage)
            return NULL;

        size_t width = CGImageGetWidth(patternImage);
        size_t height = CGImageGetHeight(patternImage);

        CGRect patternBounds = CGRectMake(0, 0, width, height);
        CGPatternRef pattern = CGPatternCreate(
            (void *)CFRetain(patternImage),
            patternBounds,
            CGAffineTransformIdentity,
            width,
            height,
            kCGPatternTilingConstantSpacingMinimalDistortion,
            YES,
            &(CGPatternCallbacks){
                .version = 0,
                .drawPattern = &drawCGImagePattern,
                .releaseInfo = &releasePatternInfo
            }
        );

        CGColorSpaceRef colorSpaceRef = CGColorSpaceCreatePattern(NULL);

        CGColorRef result = CGColorCreateWithPattern(colorSpaceRef, pattern, (CGFloat[]){ 1.0 });

        CGColorSpaceRelease(colorSpaceRef);
        CGPatternRelease(pattern);

        return (CGColorRef)[(id)result autorelease];
    }

    NSColorSpace *colorSpace = [NSColorSpace genericRGBColorSpace];
    NSColor *color = [self colorUsingColorSpace:colorSpace];

    NSInteger count = [color numberOfComponents];
    CGFloat components[count];
    [color getComponents:components];

    CGColorSpaceRef colorSpaceRef = colorSpace.CGColorSpace;
    CGColorRef result = CGColorCreate(colorSpaceRef, components);

    return (CGColorRef)[(id)result autorelease];
}

@end
