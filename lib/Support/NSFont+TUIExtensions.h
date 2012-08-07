//
//  NSFont+TUIExtensions.h
//  TwUI
//
//  Created by Josh Abernathy on 7/26/12.
//
//

#import <Cocoa/Cocoa.h>


@interface NSFont (TUIExtensions)

// Creates and returns a new font with the given size and fallback font names.
// The fallback fonts all use the font size passed in.
+ (NSFont *)tui_fontWithName:(NSString *)fontName size:(CGFloat)fontSize fallbackNames:(NSArray *)fallbackNames;

@end
