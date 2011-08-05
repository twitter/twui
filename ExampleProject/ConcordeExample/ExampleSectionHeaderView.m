#import "ExampleSectionHeaderView.h"

@implementation ExampleSectionHeaderView

@synthesize labelRenderer = _labelRenderer;

/**
 * Clean up
 */
-(void)dealloc {
  [_labelRenderer release];
  [super dealloc];
}

/**
 * Initialize
 */
-(id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		_labelRenderer = [[TUITextRenderer alloc] init];
		self.textRenderers = [NSArray arrayWithObjects:_labelRenderer, nil];
	}
	return self;
}

/**
 * Drawing
 */
-(void)drawRect:(CGRect)rect {
  
  CGContextRef g;
  if((g = TUIGraphicsGetCurrentContext()) != nil){
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:g flipped:FALSE]];
    
    NSColor *start = [NSColor colorWithCalibratedRed:0.8 green:0.8 blue:0.8 alpha:1];
    NSColor *end = [NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0.9 alpha:1];
    NSGradient *gradient = nil;
    
    gradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
    [gradient drawInRect:self.bounds angle:90];
    [gradient release];
    
    [[start shadowWithLevel:0.1] set];
    NSRectFill(NSMakeRect(0, 0, self.bounds.size.width, 1));
    
    CGFloat labelHeight = 18;
    self.labelRenderer.frame = CGRectMake(15, roundf((self.bounds.size.height - labelHeight) / 2.0), self.bounds.size.width - 30, labelHeight);
    [self.labelRenderer draw];
    
  }
  
}

@end
