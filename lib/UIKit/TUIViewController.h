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

@class TUINavigationItem;

@interface TUIViewController : TUIResponder <NSCopying>
{
	TUIView           *_view;
	TUIViewController *_parentViewController; // Nonretained
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

@property(nonatomic,strong) TUIView *view;

- (void)loadView;
- (void)viewDidLoad;
- (void)viewDidUnload;
- (BOOL)isViewLoaded;

- (void)viewWillAppear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
- (void)viewWillDisappear:(BOOL)animated;
- (void)viewDidDisappear:(BOOL)animated;

- (void)didReceiveMemoryWarning;

@property(nonatomic,weak) TUIViewController *parentViewController; // If this view controller is inside a navigation controller or tab bar controller, or has been presented modally by another view controller, return it.

- (TUIView *)setupStandardView; // don't use this

@end
