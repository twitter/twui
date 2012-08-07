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

#import "TUIViewController.h"
#import "TUIView.h"

@implementation TUIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	return [self init];
}


- (id)copyWithZone:(NSZone *)zone
{
	TUIViewController *v = [[[self class] alloc] init];
	// subclasses should override, call super, and copy over necessary properties
	return v;
}

- (TUIView *)view
{
	if(!_view) {
		[self loadView];
		[self viewDidLoad];
		[_view setNextResponder:self];
	}
	return _view;
}

- (void)setView:(TUIView *)v
{
	_view = v;
	
	if(!_view) {
		[self viewDidUnload];
	}
}

- (BOOL)performKeyEquivalent:(NSEvent *)event
{
	return NO;
}

- (void)loadView
{
	// subclasses must implement
}

- (void)viewDidLoad
{
	
}

- (void)viewDidUnload
{
	
}

- (BOOL)isViewLoaded
{
	return _view != nil;
}

- (void)viewWillAppear:(BOOL)animated { }
- (void)viewDidAppear:(BOOL)animated { }
- (void)viewWillDisappear:(BOOL)animated { }
- (void)viewDidDisappear:(BOOL)animated { }

- (void)didReceiveMemoryWarning // Called when the parent application receives a memory warning. Default implementation releases the view if it doesn't have a superview.
{
	if(_view && !_view.superview) {
		self.view = nil;
	}
}

- (TUIViewController *)parentViewController
{
	return _parentViewController;
}

- (void)setParentViewController:(TUIViewController *)v
{
	_parentViewController = v;
}

- (TUIResponder *)initialFirstResponder
{
	return _view.initialFirstResponder;
}

- (TUIView *)setupStandardView
{
	TUIView *v = [[TUIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
	v.backgroundColor = [NSColor colorWithCalibratedWhite:0.96 alpha:1.0];
	self.view = v;
	
	return v;
}

@end
