//
//  NSFont+TUIExtensions.m
//  TwUI
//
//  Created by Josh Abernathy on 7/26/12.
//
//

#import "NSFont+TUIExtensions.h"


@implementation NSFont (TUIExtensions)

+ (NSFont *)tui_fontWithName:(NSString *)fontName size:(CGFloat)fontSize fallbackNames:(NSArray *)fallbackNames {
	NSMutableArray *fallbackDescriptors = [NSMutableArray arrayWithCapacity:fallbackNames.count];
	for(NSString *fallbackName in fallbackNames) {
		[fallbackDescriptors addObject:[NSFontDescriptor fontDescriptorWithName:fallbackName size:fontSize]];
	}
	
	return [NSFont fontWithDescriptor:[NSFontDescriptor fontDescriptorWithFontAttributes:@{ NSFontNameAttribute: fontName, NSFontCascadeListAttribute: fallbackDescriptors }] size:fontSize];
}

@end
