#import <objc/runtime.h>
#import "TUILayoutConstraint.h"
#import "TUILayoutManager.h"
#import "TUIView+Layout.h"

@interface TUILayoutConstraint ()

@property (nonatomic, copy) NSValueTransformer *valueTransformer;

- (CGFloat)transformValue:(CGFloat)original;
- (void)applyToTargetView:(TUIView *)target;
- (void)applyToTargetView:(TUIView *)target sourceView:(TUIView *)source;

@end

@interface TUILayoutContainer : NSObject

@property (nonatomic, copy) NSString *layoutName;
@property (nonatomic, strong, readonly) NSMutableArray *layoutConstraints;

@end

@implementation TUILayoutContainer

@synthesize layoutName = _layoutName;
@synthesize layoutConstraints = _layoutConstraints;

+ (id)container {
	return [[self alloc] init];
}

- (id)init {
	if((self = [super init])) {
		_layoutConstraints = [[NSMutableArray alloc] init];
	}
	return self;
}

@end

@interface TUILayoutManager ()

@property (nonatomic, assign, getter = isProcessingChanges) BOOL processingChanges;

@property (nonatomic, strong) NSMapTable *constraints;
@property (nonatomic, strong) NSMutableArray *viewsToProcess;
@property (nonatomic, strong) NSMutableSet *processedViews;

@end

@implementation TUILayoutManager

@synthesize processingChanges = _processingChanges;
@synthesize constraints = _constraints;
@synthesize viewsToProcess = _viewsToProcess;
@synthesize processedViews = _processedViews;

+ (id)sharedLayoutManager {
	static TUILayoutManager *_sharedLayoutManager = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		_sharedLayoutManager = [[TUILayoutManager alloc] init];
	});
	
	return _sharedLayoutManager;
}

- (id)init {
	if((self = [super init])) {
		[[NSNotificationCenter defaultCenter] addObserver:self
	                                             selector:@selector(frameChanged:)
		                                             name:TUIViewFrameDidChangeNotification
		                                           object:nil];
		_processingChanges = NO;
		
		_constraints = [NSMapTable mapTableWithWeakToStrongObjects];
		_viewsToProcess = [[NSMutableArray alloc] init];
		_processedViews = [[NSMutableSet alloc] init];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)removeAllLayoutConstraints {
	[self.constraints removeAllObjects];
}

- (void)processView:(TUIView *)aView {
	[self.processedViews addObject:aView];
	
	NSArray *viewConstraints = [self layoutConstraintsOnView:aView];
	for(TUILayoutConstraint * constraint in viewConstraints)
		[constraint applyToTargetView:aView];
	
	// Order of Operations:
	// 1.  Siblings with constraints to this view.
	// 2.  Children with constraints to superview.
	
	if([self layoutNameForView:aView] != nil) {
		NSArray *siblings = [[aView superview] subviews];
		for(TUIView *subview in siblings) {
			if(subview == aView) continue;
			
			NSArray *subviewConstraints = [self layoutConstraintsOnView:subview];
			for(TUILayoutConstraint *subviewConstraint in subviewConstraints) {
				TUIView *sourceView = [subview relativeViewForName:[subviewConstraint sourceName]];
				if(sourceView == aView)
					[subviewConstraint applyToTargetView:subview sourceView:sourceView];
			}
		}
	}
	
	NSArray *subviews = [aView subviews];
	for(TUIView *subview in subviews) {
		NSArray *subviewConstraints = [self layoutConstraintsOnView:subview];
		for(TUILayoutConstraint *subviewConstraint in subviewConstraints) {
			TUIView *sourceView = [subview relativeViewForName:[subviewConstraint sourceName]];
			if(sourceView == aView)
				[subviewConstraint applyToTargetView:subview sourceView:sourceView];
		}
	}
}

- (void)beginProcessingView:(TUIView *)view {
	if(self.processingChanges == NO) {
		self.processingChanges = YES;
		
		@autoreleasepool {
			[self.viewsToProcess addObject:view];
			
			while([self.viewsToProcess count] > 0) {
				TUIView *currentView = [self.viewsToProcess objectAtIndex:0];
				[self.viewsToProcess removeObjectAtIndex:0];			
				if([self.viewsToProcess containsObject:currentView] == NO)
					[self processView:currentView];
			}
			
			[self.viewsToProcess removeAllObjects];
			[self.processedViews removeAllObjects];
		}
		
		self.processingChanges = NO;
	} else {
		if([self.processedViews containsObject:view] == NO)
			[self.viewsToProcess addObject:view];
	}
}

- (void)frameChanged:(NSNotification *)notification {
	TUIView *view = [notification object];
	[self beginProcessingView:view];
}

- (void)addLayoutConstraint:(TUILayoutConstraint *)constraint toView:(TUIView *)view {
	TUILayoutContainer *viewContainer = [self.constraints objectForKey:view];
	if(viewContainer == nil) {
		viewContainer = [TUILayoutContainer container];
		[self.constraints setObject:viewContainer forKey:view];
	}
	
	[[viewContainer layoutConstraints] addObject:constraint];
	[self beginProcessingView:view];
}

- (void)removeLayoutConstraintsFromView:(TUIView *)view {
	TUILayoutContainer *viewContainer = [self.constraints objectForKey:view];
	[[viewContainer layoutConstraints] removeAllObjects];
	[self.constraints removeObjectForKey:view];
}

- (NSArray *)layoutConstraintsOnView:(TUIView *)view {
	TUILayoutContainer *container = [self.constraints objectForKey:view];
	
	if(!container) return nil;
	else return [[container layoutConstraints] copy];
}

- (NSString *)layoutNameForView:(TUIView *)view {
	TUILayoutContainer *container = [self.constraints objectForKey:view];
	return [container layoutName];
}

- (void)setLayoutName:(NSString *)name forView:(TUIView *)view {
	TUILayoutContainer *viewContainer = [self.constraints objectForKey:view];
	
	if(name == nil && [[viewContainer layoutConstraints] count] == 0)
		[self.constraints removeObjectForKey:view];
	else {
		if(viewContainer == nil) {
			viewContainer = [TUILayoutContainer container];
			[self.constraints setObject:viewContainer forKey:view];
		}
		[viewContainer setLayoutName:name];
	}
}

@end
