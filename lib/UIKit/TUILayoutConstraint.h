@class TUIView;

typedef enum : NSUInteger {
    
    /*
                 MaxY
          -----------------
          |        |      | Height
          |        |      |
          |      MidY     |
     MinX |------MidX-----| MaxX
          |        |      |
          |        |      |
          ----------------- Width
                 MinY
     */
	TUILayoutConstraintAttributeMinY    = 1,
	TUILayoutConstraintAttributeMaxY    = 2,
	TUILayoutConstraintAttributeMinX    = 3,
	TUILayoutConstraintAttributeMaxX    = 4,
	TUILayoutConstraintAttributeWidth   = 5,
	TUILayoutConstraintAttributeHeight  = 6,
	TUILayoutConstraintAttributeMidY    = 7,
	TUILayoutConstraintAttributeMidX    = 8,
	
    /*
      MaxXMinY    MidXMaxY     MaxXMaxY
              -----------------
              |               |
              |               |
      MinXMidY|               |MaxXMidY
              |               |
              |               |
              |               |
              ----------------- 
      MinXMinY    MidXMinY     MaxXMinY
     */
    
	TUILayoutConstraintAttributeMinXMinY = 101,
	TUILayoutConstraintAttributeMinXMidY = 102,
	TUILayoutConstraintAttributeMinXMaxY = 103,
	
	TUILayoutConstraintAttributeMidXMinY = 104,
	TUILayoutConstraintAttributeMidXMidY = 105,
	TUILayoutConstraintAttributeMidXMaxY = 106,
	
	TUILayoutConstraintAttributeMaxXMinY = 107,
	TUILayoutConstraintAttributeMaxXMidY = 108,
	TUILayoutConstraintAttributeMaxXMaxY = 109,
	
	/*
	 BoundsCenter is the center of the view bounds.
	 Frame is the frame of the view.
	 Bounds is the bounds of the view.
	 */
	
	TUILayoutConstraintAttributeBoundsCenter = 110,
	
	TUILayoutConstraintAttributeFrame   = 1000,
	TUILayoutConstraintAttributeBounds  = 1001
} TUILayoutConstraintAttribute;

/*
 A block that contains a transformation to apply on
 source CGFloat and returns a transformed value.
 */
typedef CGFloat (^TUILayoutTransformer)(CGFloat);

/*
 
 Layout Constraint Solver System
 Based on the CAConstraint and Cocoa Auto Layout systems.
 
 Example Code:
 
 ```
 TUIButton *acceptButton = [TUIButton buttonWithType:TUIButtonTypeCustom];
 [self setUpButton:acceptButton];
 TUIButton *declineButton = [TUIButton buttonWithType:TUIButtonTypeCustom];
 [self setUpButton:declineButton];
 [acceptButton setLayoutName:@"accept"];
 [declineButton setLayoutName:@"decline"];
 
 TUILayoutConstraint *constrainLeft = [TUILayoutConstraint constraintWithAttribute:TUILayoutConstraintAttributeMaxX
                                                                        relativeTo:@"accept" 
                                                                         attribute:TUILayoutConstraintAttributeMinX
                                                                            offset:-10];
 [declineButton addConstraint:constrainLeft];
 ```
 
 Now whenever the window is resized or moved, and the acceptButton is subsequently
 resized or moved, declineButton will be automatically moved to have its right edge 
 positioned 10 pixels to the left of acceptButton left edge.
 This is only a simple example, a more complex example could use block transformers
 and a fabs(sinf()) to constrict a tranformation to a |sin(x)| curve, like below.
 
 ```
 TUIButton *helpButton = [TUIButton buttonWithType:TUIButtonTypeCustom];
 [self setUpButton:helpButton];
 [helpButton setLayoutName:@"help"];
 
 [helpButton addConstraint:[TUILayoutConstraint constraintWithAttribute:CHLayoutConstraintAttributeMinY
                                                             relativeTo:@"accept"
                                                              attribute:CHLayoutConstraintAttributeMinY
                                                       blockTransformer:^(CGFloat source) {
     return fabs((50 * sinf(source))) + 20;
 ]];
 
 [helpButton addConstraint:[TUILayoutConstraint constraintWithAttribute:CHLayoutConstraintAttributeCenter
                                                             relativeTo:@"superview"
                                                              attribute:CHLayoutConstraintAttributeFrame]];
 ```
 
 Along with simple scale and offset constraints, you can specify a block
 value transformer to use more complex transformations. You can also bind
 to point and rect values such as frame and bounds, and vertices.
 
 CAUTION: It's very easy to set up circular dependancies with constraints.
 While this leads to some very oddly cool things, here lie dragons. Beware.
 
 NOTE: To constrain a view to its superview, use the source name @"superview".
 This also means that you can't use views with a layout name @"superview".
 
 NOTE: For now, constraints have no priority levels, so they are evaluated
 in the order they are added. 
 
 NOTE: Transformations only apply to scalar attributes, and cannot be applied
 to CGPoints, or CGRects. An attribute cannot be constrained to an attribute 
 of a different type, such as scalar-point, point-rect.
 
 */

@interface TUILayoutConstraint : NSObject

@property (readonly) TUILayoutConstraintAttribute attribute;
@property (readonly) TUILayoutConstraintAttribute sourceAttribute;
@property (readonly) NSString *sourceName;

+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                   relativeTo:(NSString *)source
                    attribute:(TUILayoutConstraintAttribute)srcAttr;
+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                   relativeTo:(NSString *)source
                    attribute:(TUILayoutConstraintAttribute)srcAttr
                       offset:(CGFloat)offset;
+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                   relativeTo:(NSString *)source
                    attribute:(TUILayoutConstraintAttribute)srcAttr
                        scale:(CGFloat)scale
                       offset:(CGFloat)offset;

+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                   relativeTo:(NSString *)source
                    attribute:(TUILayoutConstraintAttribute)srcAttr
             blockTransformer:(TUILayoutTransformer)transformer;
+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                   relativeTo:(NSString *)source
                    attribute:(TUILayoutConstraintAttribute)srcAttr
             valueTransformer:(NSValueTransformer *)transformer;

@end
