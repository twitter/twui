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
    
    CGContextSetRGBFillColor(g, 0.8, 0.8, 0.8, 1);
    CGContextFillRect(g, self.bounds);
    
    CGFloat labelHeight = 18;
    self.labelRenderer.frame = CGRectMake(15, roundf((self.bounds.size.height - labelHeight) / 2.0), self.bounds.size.width - 30, labelHeight);
    [self.labelRenderer draw];
    
  }
  
}

@end
