/*
 Copyright 2012 Twitter, Inc.
 
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

@class TUIPopover;
@class TUIViewController;
@class TUIColor;

enum _TUIPopoverViewControllerBehaviour
{
    TUIPopoverViewControllerBehaviourApplicationDefined = 0,
    TUIPopoverViewControllerBehaviourTransient = 1,
    TUIPopoverViewControllerBehaviourSemiTransient = 2 //Currently not supported, here for forwards compatibility purposes
};

typedef NSUInteger TUIPopoverViewControllerBehaviour;

typedef void (^TUIPopoverDelegateBlock)(TUIPopover *popover);

@interface TUIPopover : NSResponder

@property (nonatomic, strong) TUIViewController *contentViewController;
@property (nonatomic, unsafe_unretained) Class backgroundViewClass; //Must be a subclass of TUIPopoverBackgroundView
@property (nonatomic, unsafe_unretained) CGSize contentSize; //CGSizeZero uses the size of the view on contentViewController
@property (nonatomic, unsafe_unretained) BOOL animates;
@property (nonatomic, unsafe_unretained) TUIPopoverViewControllerBehaviour behaviour;
@property (nonatomic, readonly) BOOL shown;
@property (nonatomic, readonly) CGRect positioningRect;

//Block callbacks
@property (nonatomic, copy) TUIPopoverDelegateBlock willCloseBlock;
@property (nonatomic, copy) TUIPopoverDelegateBlock didCloseBlock;

@property (nonatomic, copy) TUIPopoverDelegateBlock willShowBlock;
@property (nonatomic, copy) TUIPopoverDelegateBlock didShowBlock;

- (id)initWithContentViewController:(TUIViewController *)viewController;

- (void)showRelativeToRect:(CGRect)positioningRect ofView:(TUIView *)positioningView preferredEdge:(CGRectEdge)preferredEdge;

- (void)close;
- (void)closeWithFadeoutDuration:(NSTimeInterval)duration;
- (IBAction)performClose:(id)sender;

@end

@interface TUIPopoverBackgroundView : TUIView

+ (CGSize)sizeForBackgroundViewWithContentSize:(CGSize)contentSize popoverEdge:(CGRectEdge)popoverEdge;
+ (CGRect)contentViewFrameForBackgroundFrame:(CGRect)frame popoverEdge:(CGRectEdge)popoverEdge;
+ (TUIPopoverBackgroundView *)backgroundViewForContentSize:(CGSize)contentSize popoverEdge:(CGRectEdge)popoverEdge originScreenRect:(CGRect)originScreenRect;

- (id)initWithFrame:(CGRect)frame popoverEdge:(CGRectEdge)popoverEdge originScreenRect:(CGRect)originScreenRect;
- (CGPathRef)newPopoverPathForEdge:(CGRectEdge)popoverEdge inFrame:(CGRect)frame; //override in subclasses to change the shape of the popover, but still use the default drawing.

//Used in the default implementation
@property (nonatomic, strong) TUIColor *strokeColor;
@property (nonatomic, strong) TUIColor *fillColor;
    
@end
