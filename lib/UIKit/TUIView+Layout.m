#import "TUIView.h"
#import "TUILayoutConstraint.h"
#import "TUILayoutManager.h"

#define TUIScalarRect(_s) (NSMakeRect((_s), 0, 0, 0))
#define TUIPointRect(_x,_y) (NSMakeRect((_x), (_y), 0, 0))

#define TUIRectScalar(_r) ((_r).origin.x)
#define TUIRectPoint(_r) ((_r).origin)

#define TUISetMinX(_r,_v) ((_r).origin.x = (_v))
#define TUISetMinY(_r,_v) ((_r).origin.y = (_v))
#define TUISetMidX(_r,_v) ((_r).origin.x = (_v) - ((_r).size.width/2))
#define TUISetMidY(_r,_v) ((_r).origin.y = (_v) - ((_r).size.height/2))
#define TUISetMaxX(_r,_v) ((_r).origin.x = (_v) - (_r).size.width)
#define TUISetMaxY(_r,_v) ((_r).origin.y = (_v) - (_r).size.height)

@interface TUIView (Layout_Private)

- (NSRect)valueForLayoutAttribute:(TUILayoutConstraintAttribute)attribute;
- (void)setValue:(NSRect)newValue forLayoutAttribute:(TUILayoutConstraintAttribute)attribute;

@end

@implementation TUIView (Layout)

- (void)setLayoutName:(NSString *)newLayoutName {
	[[TUILayoutManager sharedLayoutManager] setLayoutName:newLayoutName forView:self];
}

- (NSString *)layoutName {
	return [[TUILayoutManager sharedLayoutManager] layoutNameForView:self];
}

- (void)addLayoutConstraint:(TUILayoutConstraint *)constraint {
	[[TUILayoutManager sharedLayoutManager] addLayoutConstraint:constraint toView:self];
}

- (NSArray *)layoutConstraints {
	return [[TUILayoutManager sharedLayoutManager] layoutConstraintsOnView:self];
}

- (void)removeAllLayoutConstraints {
	[[TUILayoutManager sharedLayoutManager] removeLayoutConstraintsFromView:self];
}

- (CGRect)valueForLayoutAttribute:(TUILayoutConstraintAttribute)attribute {
	CGRect frame = self.frame;
	CGRect bounds = self.bounds;
	
	switch(attribute) {
		case TUILayoutConstraintAttributeMinY:
			return TUIScalarRect(NSMinY(frame));
		case TUILayoutConstraintAttributeMaxY:
			return TUIScalarRect(NSMaxY(frame));
		case TUILayoutConstraintAttributeMinX:
			return TUIScalarRect(NSMinX(frame));
		case TUILayoutConstraintAttributeMaxX:
			return TUIScalarRect(NSMaxX(frame));
		case TUILayoutConstraintAttributeWidth:
			return TUIScalarRect(NSWidth(frame));
		case TUILayoutConstraintAttributeHeight:
			return TUIScalarRect(NSHeight(frame));
		case TUILayoutConstraintAttributeMidY:
			return TUIScalarRect(NSMidY(frame));
		case TUILayoutConstraintAttributeMidX:
			return TUIScalarRect(NSMidX(frame));
		case TUILayoutConstraintAttributeMinXMinY:
			return TUIPointRect(NSMinX(frame), NSMinY(frame));
		case TUILayoutConstraintAttributeMinXMidY:
			return TUIPointRect(NSMinX(frame), NSMidY(frame));
		case TUILayoutConstraintAttributeMinXMaxY:
			return TUIPointRect(NSMinX(frame), NSMaxY(frame));
		case TUILayoutConstraintAttributeMidXMinY:
			return TUIPointRect(NSMidX(frame), NSMinY(frame));
		case TUILayoutConstraintAttributeMidXMidY:
			return TUIPointRect(NSMidX(frame), NSMidY(frame));
		case TUILayoutConstraintAttributeMidXMaxY:
			return TUIPointRect(NSMidX(frame), NSMaxY(frame));
		case TUILayoutConstraintAttributeMaxXMinY:
			return TUIPointRect(NSMaxX(frame), NSMinY(frame));
		case TUILayoutConstraintAttributeMaxXMidY:
			return TUIPointRect(NSMaxX(frame), NSMidY(frame));
		case TUILayoutConstraintAttributeMaxXMaxY:
			return TUIPointRect(NSMaxX(frame), NSMaxY(frame));
		case TUILayoutConstraintAttributeBoundsCenter:
			return TUIPointRect(NSMidX(bounds), NSMidY(bounds));
		case TUILayoutConstraintAttributeFrame:
			return frame;
		case TUILayoutConstraintAttributeBounds:
			return bounds;
		default:
			NSAssert(NO, @"Invalid constraint attribute.");
			return NSZeroRect;
	}
}

- (void)setValue:(CGRect)newValue forLayoutAttribute:(TUILayoutConstraintAttribute)attribute {
	CGRect frame = self.frame;
	CGRect bounds = self.bounds;
	
	CGFloat scalarValue = TUIRectScalar(newValue);
	CGPoint pointValue = TUIRectPoint(newValue);
	CGRect rectValue = newValue;
	
	switch(attribute) {
		case TUILayoutConstraintAttributeMinY:
			TUISetMinY(frame, scalarValue);
			break;
		case TUILayoutConstraintAttributeMaxY:
			TUISetMaxY(frame, scalarValue);
			break;
		case TUILayoutConstraintAttributeMinX:
			TUISetMinX(frame, scalarValue);
			break;
		case TUILayoutConstraintAttributeMaxX:
			TUISetMaxX(frame, scalarValue);
			break;
		case TUILayoutConstraintAttributeWidth:
			frame.size.width = scalarValue;
			break;
		case TUILayoutConstraintAttributeHeight:
			frame.size.height = scalarValue;
			break;
		case TUILayoutConstraintAttributeMidY:
			TUISetMidY(frame, scalarValue);
			break;
		case TUILayoutConstraintAttributeMidX:
			TUISetMidX(frame, scalarValue);
			break;
		case TUILayoutConstraintAttributeMinXMinY:
			TUISetMinX(frame, pointValue.x);
			TUISetMinY(frame, pointValue.y);
			break;
		case TUILayoutConstraintAttributeMinXMidY:
			TUISetMinX(frame, pointValue.x);
			TUISetMidY(frame, pointValue.y);
			break;
		case TUILayoutConstraintAttributeMinXMaxY:
			TUISetMinX(frame, pointValue.x);
			TUISetMaxY(frame, pointValue.y);
			break;
		case TUILayoutConstraintAttributeMidXMinY:
			TUISetMidX(frame, pointValue.x);
			TUISetMinY(frame, pointValue.y);
			break;
		case TUILayoutConstraintAttributeMidXMidY:
			TUISetMidX(frame, pointValue.x);
			TUISetMidY(frame, pointValue.y);
			break;
		case TUILayoutConstraintAttributeBoundsCenter:
			TUISetMidX(bounds, pointValue.x);
			TUISetMidY(bounds, pointValue.y);
			[self setBounds:bounds];
			break;
		case TUILayoutConstraintAttributeMidXMaxY:
			TUISetMidX(frame, pointValue.x);
			TUISetMaxY(frame, pointValue.y);
			break;
		case TUILayoutConstraintAttributeMaxXMinY:
			TUISetMaxX(frame, pointValue.x);
			TUISetMinY(frame, pointValue.y);
			break;
		case TUILayoutConstraintAttributeMaxXMidY:
			TUISetMaxX(frame, pointValue.x);
			TUISetMidY(frame, pointValue.y);
			break;
		case TUILayoutConstraintAttributeMaxXMaxY:
			TUISetMaxX(frame, pointValue.x);
			TUISetMaxY(frame, pointValue.y);
			break;
		case TUILayoutConstraintAttributeFrame:
			frame = rectValue;
			break;
		case TUILayoutConstraintAttributeBounds:
			bounds = rectValue;
			[self setBounds:bounds];
			break;
		default:
			NSAssert(NO, @"Invalid constraint attribute.");
			break;
	}
	
	[self setFrame:frame];
}

- (TUIView *)relativeViewForName:(NSString *)name {
	if([name isEqual:@"superview"])
		return [self superview];
	
	NSArray *siblings = [[self superview] subviews];
	for(TUIView *view in siblings)
		if([view.layoutName isEqual:name])
			return (view == self ? nil : view);
	return nil;
}

@end
