/*
 Copyright 2011 Twitter, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this work except in compliance with the License.
 You may obtain a copy of the License in the LICENSE file, or at:
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "TUIScrollView.h"
#import "TUIScrollKnob.h"
#import "TUIView+Private.h"
#import "TUINSView.h"

#define KNOB_Z_POSITION 6000

#define FORCE_ENABLE_BOUNCE 1

#define TUIScrollViewContinuousScrollDragBoundary 25.0
#define TUIScrollViewContinuousScrollRate         10.0

enum {
	ScrollPhaseNormal = 0,
	ScrollPhaseThrowingBegan = 1,
	ScrollPhaseThrowing = 2,
	ScrollPhaseThrowingEnded = 3,
};

enum {
	AnimationModeThrow,
	AnimationModeScrollTo,
	AnimationModeScrollContinuous,
};

@interface TUIScrollView (Private)
- (void)_updateScrollKnobs;
- (void)_updateBounce;
- (void)_startTimer:(int)scrollMode;
@end

@implementation TUIScrollView

@synthesize decelerationRate;
@synthesize resizeKnobSize;

+ (Class)layerClass
{
	return [CAScrollLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame]))
	{
		_layer.masksToBounds = NO; // differs from UIKit

		decelerationRate = 0.88;
		
		_scrollViewFlags.bounceEnabled = (FORCE_ENABLE_BOUNCE || AtLeastLion || [[NSUserDefaults standardUserDefaults] boolForKey:@"ForceEnableScrollBouncing"]);
		
		_scrollViewFlags.showsHorizontalScrollIndicator = 1;
		_scrollViewFlags.showsVerticalScrollIndicator = 1;
		
		_horizontalScrollKnob = [[TUIScrollKnob alloc] initWithFrame:CGRectZero];
		_horizontalScrollKnob.scrollView = self;
		_horizontalScrollKnob.layer.zPosition = KNOB_Z_POSITION;
		_horizontalScrollKnob.hidden = YES;
		_horizontalScrollKnob.opaque = NO;
		[self addSubview:_horizontalScrollKnob];
		
		_verticalScrollKnob = [[TUIScrollKnob alloc] initWithFrame:CGRectZero];
		_verticalScrollKnob.scrollView = self;
		_verticalScrollKnob.layer.zPosition = KNOB_Z_POSITION;
		_verticalScrollKnob.hidden = YES;
		_verticalScrollKnob.opaque = NO;
		[self addSubview:_verticalScrollKnob];
	}
	return self;
}

- (void)dealloc
{
	[scrollTimer invalidate];
	[scrollTimer release];
	scrollTimer = nil;
	
	[_horizontalScrollKnob release];
	[_verticalScrollKnob release];
	
	[super dealloc];
}

- (id<TUIScrollViewDelegate>)delegate
{
	return _delegate;
}

- (void)setDelegate:(id<TUIScrollViewDelegate>)d
{
	_delegate = d;
	_scrollViewFlags.delegateScrollViewDidScroll = [_delegate respondsToSelector:@selector(scrollViewDidScroll:)];
	_scrollViewFlags.delegateScrollViewWillBeginDragging = [_delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)];
	_scrollViewFlags.delegateScrollViewDidEndDragging = [_delegate respondsToSelector:@selector(scrollViewDidEndDragging:)];
}

- (TUIScrollViewIndicatorStyle)indicatorStyle
{
	return _scrollViewFlags.indicatorStyle;
}

- (void)setIndicatorStyle:(TUIScrollViewIndicatorStyle)s
{
	_scrollViewFlags.indicatorStyle = s;
}

- (BOOL)isScrollEnabled
{
	return !_scrollViewFlags.scrollDisabled;
}

- (void)setScrollEnabled:(BOOL)b
{
	_scrollViewFlags.scrollDisabled = !b;
}

- (BOOL)showsHorizontalScrollIndicator
{
	return _scrollViewFlags.showsHorizontalScrollIndicator;
}

- (BOOL)showsVerticalScrollIndicator
{
	return _scrollViewFlags.showsVerticalScrollIndicator;
}

- (void)setShowsHorizontalScrollIndicator:(BOOL)b
{
	_scrollViewFlags.showsHorizontalScrollIndicator = b;
}

- (void)setShowsVerticalScrollIndicator:(BOOL)b
{
	_scrollViewFlags.showsVerticalScrollIndicator = b;
}

- (TUIEdgeInsets)contentInset
{
	return _contentInset;
}

- (void)setContentInset:(TUIEdgeInsets)i
{
	if(!TUIEdgeInsetsEqualToEdgeInsets(i, _contentInset)) {
		_contentInset = i;
		
		if(_pull.pulling) {
			_scrollViewFlags.didChangeContentInset = 1;
		} else {
			if(!self.dragging) {
				self.contentOffset = self.contentOffset;
			}
		}
	}
}

- (CGRect)visibleRect
{
	CGRect b = self.bounds;
	CGPoint offset = self.contentOffset;
	offset.x = -offset.x;
	offset.y = -offset.y;
	b.origin = offset;
	return b;
}

- (void)_startTimer:(int)scrollMode
{
	_scrollViewFlags.animationMode = scrollMode;
	_throw.t = CFAbsoluteTimeGetCurrent();
	_bounce.bouncing = NO;
	
	if(!scrollTimer) {
		scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:1/60. target:self selector:@selector(tick:) userInfo:nil repeats:YES] retain];
	}
}

- (void)_stopTimer
{
	if(scrollTimer) {
		[scrollTimer invalidate];
		[scrollTimer release];
		scrollTimer = nil;
	}
	_bounce.bouncing = 0;
	[self _updateBounce];
}

- (void)willMoveToWindow:(TUINSWindow *)newWindow
{
	[super willMoveToWindow:newWindow];
	if(!newWindow) {
		x = YES;
		[self _stopTimer];
	}
}

- (CGPoint)_fixProposedContentOffset:(CGPoint)offset
{
	CGRect b = self.bounds;
	CGSize s = _contentSize;
	
	s.height += _contentInset.top;
	
	CGFloat mx = offset.x + s.width;
	if(s.width > b.size.width) {
		if(mx < b.size.width) {
			offset.x = b.size.width - s.width;
		}
		if(offset.x > 0.0) {
			offset.x = 0.0;
		}
	} else {
		if(mx > b.size.width) {
			offset.x = b.size.width - s.width;
		}
		if(offset.x < 0.0) {
			offset.x = 0.0;
		}
	}

	CGFloat my = offset.y + s.height;
	if(s.height > b.size.height) { // content bigger than bounds
		if(my < b.size.height) {
			offset.y = b.size.height - s.height;
		}
		if(offset.y > 0.0) {
			offset.y = 0.0;
		}
	} else { // content smaller than bounds
		if(0) { // let it move around in bounds
			if(my > b.size.height) {
				offset.y = b.size.height - s.height;
			}
			if(offset.y < 0.0) {
				offset.y = 0.0;
			}
		}
		if(1) { // pin to top
			offset.y = b.size.height - s.height;
		}
	}
	
	return offset;
}

- (void)setResizeKnobSize:(CGSize)s
{
	if(AtLeastLion) {
		// ignore
	} else {
		resizeKnobSize = s;
	}
}

- (void)_updateScrollKnobs
{
	CGPoint offset = _unroundedContentOffset;
	CGRect bounds = self.bounds;
	CGFloat knobSize = 12;
	
	BOOL vVisible = (self.contentSize.height > self.bounds.size.height) && _scrollViewFlags.showsVerticalScrollIndicator;
	BOOL hVisible = (self.contentSize.width > self.bounds.size.width) && _scrollViewFlags.showsHorizontalScrollIndicator;
	
//	float bounceX = (-self.bounceOffset.x - self.pullOffset.x) * 1.2;
	float bounceY = (-self.bounceOffset.y - self.pullOffset.y) * 1.2;
	
	_verticalScrollKnob.frame = CGRectMake(round(-offset.x + bounds.size.width - knobSize), // x
										   round(-offset.y + (hVisible?knobSize:0) + resizeKnobSize.height + bounceY), // y
										   knobSize, // width
										   bounds.size.height - (hVisible?knobSize:0) - resizeKnobSize.height); // height

	_horizontalScrollKnob.frame = CGRectMake(round(-offset.x), // x
											 round(-offset.y), // y
											 bounds.size.width - (vVisible?knobSize:0) - resizeKnobSize.width, // width
											 knobSize); // height

	_verticalScrollKnob.hidden = !vVisible;
	_horizontalScrollKnob.hidden = !hVisible;
	
	_horizontalScrollKnob.alpha = 1.0;
	_verticalScrollKnob.alpha = 1.0;
	
	if(vVisible)
		[_verticalScrollKnob setNeedsLayout];
	if(hVisible)
		[_horizontalScrollKnob setNeedsLayout];
}

- (void)layoutSubviews
{
	self.contentOffset = _unroundedContentOffset;
	[self _updateScrollKnobs];
}

static CGFloat lerp(CGFloat a, CGFloat b, CGFloat t)
{
	return a - t * (a+b);
}
					
static CGFloat clamp(CGFloat x, CGFloat min, CGFloat max)
{
	if(x < min) return min;
	if(x > max) return max;
	return x;
}

static CGFloat PointDist(CGPoint a, CGPoint b)
{
	CGFloat dx = a.x - b.x;
	CGFloat dy = a.y - b.y;
	return sqrt(dx*dx + dy*dy);
}

static CGPoint PointLerp(CGPoint a, CGPoint b, CGFloat t)
{
	CGPoint p;
	p.x = lerp(a.x, b.x, t);
	p.y = lerp(a.y, b.y, t);
	return p;
}

- (CGPoint)contentOffset
{
	CGPoint p = _unroundedContentOffset;
	p.x = roundf(p.x);
	p.y = roundf(p.y + self.bounceOffset.y + self.pullOffset.y);
	return p;
}

- (CGPoint)pullOffset
{
	if(_scrollViewFlags.bounceEnabled)
		return _pull.pulling?CGPointMake(_pull.x, _pull.y):CGPointZero;
	return CGPointZero;
}

- (CGPoint)bounceOffset
{
	if(_scrollViewFlags.bounceEnabled)
		return _bounce.bouncing?CGPointMake(_bounce.x, _bounce.y):CGPointZero;
	return CGPointZero;
}

- (void)_setContentOffset:(CGPoint)p
{
	_unroundedContentOffset = p;
	p.x = round(-p.x);
	p.y = round(-p.y - self.bounceOffset.y - self.pullOffset.y);
	[((CAScrollLayer *)self.layer) scrollToPoint:p];
	if(_scrollViewFlags.delegateScrollViewDidScroll)
		[_delegate scrollViewDidScroll:self];
}

- (void)setContentOffset:(CGPoint)p
{
	[self _setContentOffset:[self _fixProposedContentOffset:p]];
}

- (CGSize)contentSize
{
	return _contentSize;
}

- (void)setContentSize:(CGSize)s
{
	_contentSize = s;
}

- (CGFloat)topDestinationOffset
{
	CGRect visible = self.visibleRect;
	return -self.contentSize.height + visible.size.height;
}

- (BOOL)isScrollingToTop
{
	if(scrollTimer) {
		if(_scrollViewFlags.animationMode == AnimationModeScrollTo) {
			if(roundf(destinationOffset.y) == roundf([self topDestinationOffset]))
				return YES;
		}
	}
	return NO;
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated
{
	if(animated) {
		destinationOffset = contentOffset;
		[self _startTimer:AnimationModeScrollTo];
	} else {
		destinationOffset = contentOffset;
		[self setContentOffset:contentOffset];
	}
}

/**
 * @brief Begin scrolling continuously for a drag
 * 
 * Content is continuously scrolled in the direction of the drag until the end
 * of the content is reached or the operation is cancelled via
 * #endContinuousScrollAnimated:.
 * 
 * @param dragLocation the drag location
 * @param animated animate the scroll or not (this is currently ignored and the scroll is always animated)
 */
- (void)beginContinuousScrollForDragAtPoint:(CGPoint)dragLocation animated:(BOOL)animated {
  if(dragLocation.y <= TUIScrollViewContinuousScrollDragBoundary || dragLocation.y >= (self.bounds.size.height - TUIScrollViewContinuousScrollDragBoundary)){
    // note the drag offset
    _dragScrollLocation = dragLocation;
    // begin a continuous scroll
    [self _startTimer:AnimationModeScrollContinuous];
  }else{
    [self endContinuousScrollAnimated:animated];
  }
}

/**
 * @brief Stop scrolling continuously for a drag
 * 
 * This method is the counterpart to #beginContinuousScrollForDragAtPoint:animated:
 * 
 * @param animated animate the scroll or not (this is currently ignored and the scroll is always animated)
 */
- (void)endContinuousScrollAnimated:(BOOL)animated {
  if(_scrollViewFlags.animationMode == AnimationModeScrollContinuous){
    [self _stopTimer];
  }
}

static float clampBounce(float x) {
	x *= 0.4;
	float m = 60 * 60;
	if(x > 0.0f)
		return MIN(x, m);
	else
		return MAX(x, -m);
}

- (void)_startBounce
{
	if(!_bounce.bouncing) {
		_bounce.bouncing = 1;
		_bounce.x = 0.0f;
		_bounce.y = 0.0f;
		_bounce.vx = clampBounce(-_throw.vx);
		_bounce.vy = clampBounce(-_throw.vy);
		_bounce.t = _throw.t;
	}
}

- (void)_updateBounce
{
	if(_bounce.bouncing) {
		CFAbsoluteTime t = CFAbsoluteTimeGetCurrent();
		double dt = t - _bounce.t;
		
		CGPoint F = CGPointZero;
		
		float tightness = 2.5;
		float dampiness = 0.3;
		
		// spring
		F.x = -_bounce.x * tightness * 0.0; // no bounce for now
		F.y = -_bounce.y * tightness;
		
		// damper
		if(fabsf(_bounce.x) > 0.0)
			F.x -= _bounce.vx * dampiness;
		if(fabsf(_bounce.y) > 0.0)
			F.y -= _bounce.vy * dampiness;
		
		_bounce.vx += F.x; // mass=1
		_bounce.vy += F.y;
		
		_bounce.x += _bounce.vx * dt;
		_bounce.y += _bounce.vy * dt;
		
		_bounce.t = t;
		
		if(fabsf(_bounce.vy) < 1.0 && fabsf(_bounce.y) < 1.0) {
			[self _stopTimer];
		}
		
		[self _updateScrollKnobs];
	}
}

- (void)tick:(NSTimer *)timer
{
	[self _updateBounce]; // can't do after _startBounce otherwise dt will be crazy
	
	if(self.nsWindow == nil) {
		NSLog(@"Warning: no window %d (should be 1)", x);
		[self _stopTimer];
		return;
	}
	
	switch(_scrollViewFlags.animationMode) {
		case AnimationModeThrow: {
			
			CGPoint o = _unroundedContentOffset;
			CFAbsoluteTime t = CFAbsoluteTimeGetCurrent();
			double dt = t - _throw.t;
			o.x = o.x + _throw.vx * dt;
			o.y = o.y - _throw.vy * dt;
			
			CGPoint fixedOffset = [self _fixProposedContentOffset:o];
			o.x = fixedOffset.x;
			if(!CGPointEqualToPoint(fixedOffset, o)) {
				[self _startBounce];
			}
			
			[self setContentOffset:o];
			
			_throw.vx *= decelerationRate;
			_throw.vy *= decelerationRate;
			_throw.t = t;
			
			if(_throw.throwing && !_pull.pulling && !_bounce.bouncing) {
				// may happen in the case where our we scrolled, then stopped, then lifted finger (didn't do a system-started throw, but timer started anyway to do something else)
				// todo - handle this before it happens, but keep this sanity check
				if(MAX(fabsf(_throw.vx), fabsf(_throw.vy)) < 0.1) {
					[self _stopTimer];
				}
			}
			
			break;
		}
		case AnimationModeScrollTo: {
			
			CGPoint o = _unroundedContentOffset;
			CGPoint lastOffset = o;
			o.x = o.x * decelerationRate + destinationOffset.x * (1-decelerationRate);
			o.y = o.y * decelerationRate + destinationOffset.y * (1-decelerationRate);
			o = [self _fixProposedContentOffset:o];
			[self _setContentOffset:o];
			
			if((fabsf(o.x - lastOffset.x) < 0.1) && (fabsf(o.y - lastOffset.y) < 0.1)) {
				[self _stopTimer];
				[self setContentOffset:destinationOffset];
			}
			
			break;
		}
    case AnimationModeScrollContinuous: {
      CGFloat direction;
      CGFloat distance;
      
      if(_dragScrollLocation.y <= TUIScrollViewContinuousScrollDragBoundary){
        distance = MAX(0, MIN(TUIScrollViewContinuousScrollDragBoundary, _dragScrollLocation.y));
        direction = 1;
      }else if(_dragScrollLocation.y >= (self.bounds.size.height - TUIScrollViewContinuousScrollDragBoundary)){
        distance = MAX(0, MIN(TUIScrollViewContinuousScrollDragBoundary, self.bounds.size.height - _dragScrollLocation.y));
        direction = -1;
      }else{
        return; // no scrolling; outside drag boundary
      }
      
			CGPoint offset = _unroundedContentOffset;
      CGFloat step = (1.0 - (distance / TUIScrollViewContinuousScrollDragBoundary)) * TUIScrollViewContinuousScrollRate;
			CGPoint dest = CGPointMake(offset.x, offset.y + (step * direction));
      
			[self setContentOffset:dest];
			
      break;
    }
	}
}

- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated
{
	CGRect visible = self.visibleRect;
	if(rect.origin.y < visible.origin.y) {
		// scroll down, have rect be flush with bottom of visible view
		[self setContentOffset:CGPointMake(0, -rect.origin.y) animated:animated];
	} else if(rect.origin.y + rect.size.height > visible.origin.y + visible.size.height) {
		// scroll up, rect to be flush with top of view
		[self setContentOffset:CGPointMake(0, -rect.origin.y + visible.size.height - rect.size.height) animated:animated];
	}
	[self.nsView invalidateHoverForView:self];
}

- (void)scrollToTopAnimated:(BOOL)animated
{
	[self setContentOffset:CGPointMake(0, [self topDestinationOffset]) animated:animated];
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
	[self setContentOffset:CGPointMake(0, 0) animated:animated];
}

- (void)pageDown:(id)sender
{
	CGPoint o = self.contentOffset;
	o.y += roundf((self.visibleRect.size.height * 0.9));
	[self setContentOffset:o animated:YES];
}

- (void)pageUp:(id)sender
{
	CGPoint o = self.contentOffset;
	o.y -= roundf((self.visibleRect.size.height * 0.9));
	[self setContentOffset:o animated:YES];
}

- (void)flashScrollIndicators
{
	[_horizontalScrollKnob flash];
	[_verticalScrollKnob flash];
}

- (BOOL)isDragging
{
	return _scrollViewFlags.gestureBegan;
}

/*
 
 10.6 throw sequence:
 
 - beginGestureWithEvent
 - ScrollPhaseNormal
 - ...
 - ScrollPhaseNormal
 - endGestureWithEvent
 - ScrollPhaseThrowingBegan
 
 [REDACTED] throw sequence:
 
 - beginGestureWithEvent
 - ScrollPhaseNormal
 - ...
 - ScrollPhaseNormal
 - endGestureWithEvent
 - ScrollPhaseNormal         <- ignore this
 - ScrollPhaseThrowingBegan
 
 */

- (void)beginGestureWithEvent:(NSEvent *)event
{
	if(_scrollViewFlags.delegateScrollViewWillBeginDragging)
		[_delegate scrollViewWillBeginDragging:self];
	
	if(_scrollViewFlags.bounceEnabled) {
		_throw.throwing = 0;
		_scrollViewFlags.gestureBegan = 1; // this won't happen if window isn't key on 10.6, lame
	}
}

- (void)_startThrow
{
	if(!_pull.pulling) {
		if(fabsf(_lastScroll.dy) < 2.0)
			return; // don't bother throwing
	}
	
	if(!_throw.throwing) {
		_throw.throwing = 1;
		
		CFAbsoluteTime t = CFAbsoluteTimeGetCurrent();
		CFTimeInterval dt = t - _lastScroll.t;
		if(dt < 1/60.0)
			dt = 1/60.0;
		_throw.vx = _lastScroll.dx / dt;
		_throw.vy = _lastScroll.dy / dt;
		_throw.t = t;
		
		[self _startTimer:AnimationModeThrow];
		
		if(_pull.pulling) {
			_pull.pulling = NO;
			
			if(signbit(_throw.vy) != signbit(_pull.y)) {
				_throw.vx = 0.0;
				_throw.vy = 0.0;
			}
			
			[self _startBounce];
			_bounce.y = _pull.y;
			
			if(_scrollViewFlags.didChangeContentInset) {
				_scrollViewFlags.didChangeContentInset = 0;
				_bounce.y += _contentInset.top;
				_unroundedContentOffset.y -= _contentInset.top;
			}
		}
	}
}

- (void)endGestureWithEvent:(NSEvent *)event
{
	if(_scrollViewFlags.delegateScrollViewDidEndDragging)
		[_delegate scrollViewDidEndDragging:self];
	
	if(_scrollViewFlags.bounceEnabled) {
		_scrollViewFlags.gestureBegan = 0;
		[self _startThrow];
		
		if(AtLeastLion) {
			_scrollViewFlags.ignoreNextScrollPhaseNormal_10_7 = 1;
		}
	}
}

- (void)scrollWheel:(NSEvent *)event
{
	if(self.scrollEnabled)
	{
		int phase = ScrollPhaseNormal;
		
		if(AtLeastLion) {
			SEL s = @selector(momentumPhase);
			if([event respondsToSelector:s]) {
				NSInteger (*imp)(id,SEL) = (NSInteger(*)(id,SEL))[event methodForSelector:s];
				NSInteger lionPhase = imp(event, s);
				
				switch(lionPhase) {
					case 1:
						phase = ScrollPhaseThrowingBegan;
						break;
					case 4:
						phase = ScrollPhaseThrowing;
						break;
					case 8:
						phase = ScrollPhaseThrowingEnded;
						break;
				}
			}
		} else {
			SEL s = @selector(_scrollPhase);
			if([event respondsToSelector:s]) {
				int (*imp)(id,SEL) = (int(*)(id,SEL))[event methodForSelector:s];
				phase = imp(event, s);
			}
		}
		
		switch(phase) {
			case ScrollPhaseNormal: {
				if(_scrollViewFlags.ignoreNextScrollPhaseNormal_10_7) {
					_scrollViewFlags.ignoreNextScrollPhaseNormal_10_7 = 0;
					return;
				}
				
				// in case we are in background, didn't get a beginGesture
				_throw.throwing = 0;
				_scrollViewFlags.didChangeContentInset = 0;
				
				[self _stopTimer];
				CGEventRef cgEvent = [event CGEvent];
				const int64_t isContinuous = CGEventGetIntegerValueField(cgEvent, kCGScrollWheelEventIsContinuous);

				double dx = 0.0;
				double dy = 0.0;
				
				if(isContinuous) {
					dx = CGEventGetDoubleValueField(cgEvent, kCGScrollWheelEventPointDeltaAxis2);
					dy = CGEventGetDoubleValueField(cgEvent, kCGScrollWheelEventPointDeltaAxis1);
				} else {
					CGEventSourceRef source = CGEventCreateSourceFromEvent(cgEvent);
					if(source) {
						const double pixelsPerLine = CGEventSourceGetPixelsPerLine(source);
						dx = CGEventGetDoubleValueField(cgEvent, kCGScrollWheelEventFixedPtDeltaAxis2) * pixelsPerLine;
						dy = CGEventGetDoubleValueField(cgEvent, kCGScrollWheelEventFixedPtDeltaAxis1) * pixelsPerLine;
						CFRelease(source);
					} else {
						NSLog(@"Critical: NULL source from CGEventCreateSourceFromEvent");
					}
				}
				
				if(MAX(fabsf(dx), fabsf(dy)) > 0.00001) { // ignore 0.0, 0.0
					_lastScroll.dx = dx;
					_lastScroll.dy = dy;
					_lastScroll.t = CFAbsoluteTimeGetCurrent();
				}
				
				CGPoint o = _unroundedContentOffset;
				
				if(!_pull.pulling) {
					o.x = o.x + dx;
					o.y = o.y - dy;
				}
				
				BOOL pulling = NO;
				{
					CGPoint pullO = o;
					pullO.y += (_pull.pulling?_pull.y:0);
					CGPoint fixedOffset = [self _fixProposedContentOffset:pullO];
					o.x = fixedOffset.x;
					pulling = !CGPointEqualToPoint(fixedOffset, o);
				}
				
				if(_scrollViewFlags.gestureBegan) {
					if(_pull.pulling) {
						
						float maxManualPull = 30.0;
						float counterPull = pow(M_E, -1/maxManualPull * fabsf(_pull.y));
						
						if(signbit(_pull.y) == signbit(dy)) // if un-pulling, don't restrict. [REDACTED] doesn't do this and it feels weird - rubber band fights you *both* ways
							counterPull = 1.0; // don't counter
						
						BOOL shouldEndPull = pulling;
						
						if(shouldEndPull) {
							_pull.pulling = NO;
						} else {
							_pull.y -= dy * counterPull;
						}
					} else {
						
						BOOL shouldStartPull = pulling;
						
						if(shouldStartPull) {
							_pull.pulling = YES;
							_pull.y = 0.0;
							_pull.y -= dy;
						}
					}
				}
				
				[self setContentOffset:o];
				break;
			}
			case ScrollPhaseThrowingBegan: {
				[self _startThrow];
				break;
			}
			case ScrollPhaseThrowing: {
				break;
			}
			case ScrollPhaseThrowingEnded: {
				if(_scrollViewFlags.animationMode == AnimationModeThrow) { // otherwise we may have started a scrollToTop:animated:, don't want to stop that)
					if(_bounce.bouncing) {
						// ignore - let the bounce finish (_updateBounce will kill the timer when it's ready)
					} else {
						[self _stopTimer];
					}
				}
				break;
			}
		}
	}
}

- (BOOL)performKeyAction:(NSEvent *)event
{
	switch([[event charactersIgnoringModifiers] characterAtIndex:0]) {
		case 63276: // page up
			[self pageUp:nil];
			return YES;
		case 63277: // page down
			[self pageDown:nil];
			return YES;
		case 63273: // home
			[self scrollToTopAnimated:YES];
			return YES;
		case 63275: // end
			[self scrollToBottomAnimated:YES];
			return YES;
		case 32:
			if([NSEvent modifierFlags] & NSShiftKeyMask)
				[self pageUp:nil];
			else
				[self pageDown:nil];
			return YES;
	}
	return NO;
}

@end
