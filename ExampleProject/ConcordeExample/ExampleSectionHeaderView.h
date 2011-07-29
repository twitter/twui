#import <Cocoa/Cocoa.h>

#import "TUIKit.h"

@interface ExampleSectionHeaderView : TUIView {
  
  TUITextRenderer * _labelRenderer;
  
}

@property (readonly) TUITextRenderer  * labelRenderer;

@end

