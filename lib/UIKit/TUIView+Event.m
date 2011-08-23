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

#import "TUIView.h"
#import "TUIView+Event.h"
#import "TUITextRenderer.h"
#import "TUITextRenderer+Event.h"
#import "TUIView+Private.h"
#import "TUIView+PasteboardDragging.h"
#import "TUINSWindow.h"

@implementation TUIView (Event)

- (TUITextRenderer *)_textRendererForEvent:(NSEvent *)event
{
	CGPoint p = [self localPointForEvent:event];
	return [self textRendererAtPoint:p];
}

- (void)mouseDown:(NSEvent *)event
{
	_currentTextRenderer = [self _textRendererForEvent:event];
	[_currentTextRenderer mouseDown:event];
	
	if(!_currentTextRenderer && _viewFlags.pasteboardDraggingEnabled)
		[self pasteboardDragMouseDown:event];
	
	startDrag = [self localPointForEvent:event];
	_viewFlags.dragDistanceLock = 1;
	_viewFlags.didStartMovingByDragging = 0;
	_viewFlags.didStartResizeByDragging = 0;
	
	if(self.superview != nil){
	  [self.superview mouseDown:event onSubview:self];
	}
	
}

- (void)mouseUp:(NSEvent *)event
{
	[_currentTextRenderer mouseUp:event];
	_currentTextRenderer = nil;
	
	if(_viewFlags.didStartResizeByDragging) {
		_viewFlags.didStartResizeByDragging = 0;
		[self.nsView viewDidEndLiveResize];
	}
	
	if(self.superview != nil){
	  [self.superview mouseUp:event fromSubview:self];
	}
	
}

- (void)rightMouseDown:(NSEvent *)event
{
	if(self.superview != nil){
	  [self.superview rightMouseDown:event onSubview:self];
	}
}

- (void)rightMouseUp:(NSEvent *)event
{
	if(self.superview != nil){
	  [self.superview rightMouseUp:event fromSubview:self];
	}
}

- (void)mouseDragged:(NSEvent *)event
{
	[_currentTextRenderer mouseDragged:event];
	NSPoint p = [self localPointForEvent:event];
	
	if(_viewFlags.dragDistanceLock) {
		CGFloat dx = p.x - startDrag.x;
		CGFloat dy = p.y - startDrag.y;
		CGFloat dragDist = sqrt(dx*dx+dy*dy);
		if(dragDist > 2.5) {
			_viewFlags.dragDistanceLock = 0;
		}
	}
	if(_viewFlags.dragDistanceLock == 1)
		return; // ignore
	
	if(_viewFlags.moveWindowByDragging) {
		NSWindow *window = [self nsWindow];
		NSPoint o = [window frame].origin;
		o.x += p.x - startDrag.x;
		o.y += p.y - startDrag.y;
		
		CGRect r = [window frame];
		r.origin = o;
		r = ABClampProposedRectToScreen(r);
		o = r.origin;
		
		if(!_viewFlags.didStartMovingByDragging) {
			if([window respondsToSelector:@selector(windowWillStartLiveDrag)])
				[window performSelector:@selector(windowWillStartLiveDrag)];
			_viewFlags.didStartMovingByDragging = 1;
		}
		[window setFrameOrigin:o];
	} else if(_viewFlags.resizeWindowByDragging) {
		if(!_viewFlags.didStartResizeByDragging) {
			_viewFlags.didStartResizeByDragging = 1;
			[self.nsView viewWillStartLiveResize];
		}
		
		NSWindow *window = [self nsWindow];
		NSRect r = [window frame];
		CGFloat dh = round(p.y - startDrag.y);
		
		if(r.size.height - dh < [window minSize].height) {
			dh = r.size.height - [window minSize].height;
		}
		
		if(r.size.height - dh > [window maxSize].height) {
			dh = r.size.height - [window maxSize].height;
		}
		
		r.origin.y += dh;
		r.size.height -= dh;
		
		CGFloat dw = round(p.x - startDrag.x);
		
		if(r.size.width + dw < [window minSize].width) {
			dw = [window minSize].width - r.size.width;
		}
		
		if(r.size.width + dw > [window maxSize].width) {
			dw = [window maxSize].width - r.size.width;
		}
		
		r.size.width += dw;
		
		[window setFrame:r display:YES];
	} else {
		if(!_currentTextRenderer && _viewFlags.pasteboardDraggingEnabled)
			[self pasteboardDragMouseDragged:event];
	}
	
	if(self.superview != nil){
	  [self.superview mouseDragged:event onSubview:self];
	}
	
}

- (BOOL)didDrag
{
	return _viewFlags.dragDistanceLock == 0;
}

- (void)scrollWheel:(NSEvent *)event
{
	[self.superview scrollWheel:event];
}

- (void)beginGestureWithEvent:(NSEvent *)event
{
	[self.superview beginGestureWithEvent:event];
}

- (void)endGestureWithEvent:(NSEvent *)event
{
	[self.superview endGestureWithEvent:event];
}

- (void)mouseEntered:(NSEvent *)event
{
  if(self.superview != nil){
    [self.superview mouseEntered:event onSubview:self];
  }
	if(_viewFlags.delegateMouseEntered){
		[_viewDelegate view:self mouseEntered:event];
	}
}

- (void)mouseExited:(NSEvent *)event
{
  if(self.superview != nil){
    [self.superview mouseExited:event fromSubview:self];
  }
	if(_viewFlags.delegateMouseExited){
		[_viewDelegate view:self mouseExited:event];
	}
}

- (void)viewWillStartLiveResize
{
	[self.subviews makeObjectsPerformSelector:@selector(viewWillStartLiveResize)];
}

- (void)viewDidEndLiveResize
{
	[self.subviews makeObjectsPerformSelector:@selector(viewDidEndLiveResize)];
}

- (void)mouseDown:(NSEvent *)event onSubview:(TUIView *)subview
{
  [self.superview mouseDown:event onSubview:subview];
}

- (void)mouseDragged:(NSEvent *)event onSubview:(TUIView *)subview
{
  [self.superview mouseDragged:event onSubview:subview];
}

- (void)mouseUp:(NSEvent *)event fromSubview:(TUIView *)subview
{
	[self.superview mouseUp:event fromSubview:subview];
}

- (void)rightMouseDown:(NSEvent *)event onSubview:(TUIView *)subview
{
  [self.superview rightMouseDown:event onSubview:subview];
}

- (void)rightMouseUp:(NSEvent *)event fromSubview:(TUIView *)subview
{
	[self.superview rightMouseUp:event fromSubview:subview];
}

- (void)mouseEntered:(NSEvent *)event onSubview:(TUIView *)subview
{
  [self.superview mouseEntered:event onSubview:subview];
}

- (void)mouseExited:(NSEvent *)event fromSubview:(TUIView *)subview
{
  [self.superview mouseExited:event fromSubview:subview];
}

@end
