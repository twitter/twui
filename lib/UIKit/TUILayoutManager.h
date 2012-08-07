@class TUILayoutConstraint;
@class TUIView;

/*
 
 The layout manager is penultimate to solving constraints. It handles
 views marked as needing processing, and recursively invokes the
 constraint solver per view when required. 
 
 However, it also provides a bridge to the constraints and the views 
 by mediating the adding or removing of a constraint to and from a view. 
 
 Views are marked by an internal layout name, to which they are 
 then referred to from within constraints. 
 
 CAUTION:
 This class has been marked as requiring refactorization
 and should not be used directly. It will become private soon.
 
 NOTE:
 Layout names as identifiers might be removed in future updates.
 
 */

@interface TUILayoutManager : NSObject

/*
 
 Requests the shared layout manager, the preferred usage method. This
 shared manager then handles the constraint system for the global space.
 
 You may also use -init to create a local layout manager, in cases where
 you may want your constraint system to be factored and isolated, or
 where you may be using TUIViews only in certain places, and not the whole
 window or application.
 
 */
+ (id)sharedLayoutManager;

/*
 
 Provides a bridge to add a constraint to a view, or remove a constraint
 from a view. You can also remove ALL layout constraints on a view, and
 retrieve an array of constraints currently attached to a view.
 
 */
- (void)addLayoutConstraint:(TUILayoutConstraint *)constraint toView:(TUIView *)view;
- (void)removeLayoutConstraintsFromView:(TUIView *)view;

- (NSArray *)layoutConstraintsOnView:(TUIView *)view;
- (void)removeAllLayoutConstraints;

/*
 Provides a bridge for the TUIView layout name identifier.
 */
- (NSString *)layoutNameForView:(TUIView *)view;
- (void)setLayoutName:(NSString *)name forView:(TUIView *)view;

/*
 Similar to -redraw on a TUIView, but for constraints. Forces a re-processing
 of all constraints attached to a view.
 */
- (void)beginProcessingView:(TUIView *)aView;

@end
