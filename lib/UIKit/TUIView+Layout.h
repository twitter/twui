#import <Cocoa/Cocoa.h>
#import "TUIView.h"

@class TUILayoutConstraint;

/*
 
 The view-end of the layout system allows you to add constraints
 to the view directly from the view, list all constraints currently
 attached to the view, and remove all layout constraints at once.
 
 It also allows you to set the layout name without interfacing
 with the TUILayoutManager, as a shortcut.
 
 */

@interface TUIView (Layout)

@property (nonatomic, copy) NSString *layoutName;

- (void)addLayoutConstraint:(TUILayoutConstraint *)constraint;
- (NSArray *)layoutConstraints;
- (void)removeAllLayoutConstraints;

- (TUIView *)relativeViewForName:(NSString *)name;

@end
