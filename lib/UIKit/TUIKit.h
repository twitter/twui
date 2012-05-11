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

#import <Foundation/Foundation.h>

#import "TUIResponder.h"
#import "TUIFont.h"
#import "TUIColor.h"
#import "TUIImage.h"
#import "TUIView.h"
#import "TUIScrollView.h"
#import "TUIFastIndexPath.h"
#import "TUITableView.h"
#import "TUITableView+Additions.h"
#import "TUITableViewCell.h"
#import "TUITableViewSectionHeader.h"
#import "TUILabel.h"
#import "TUIImageView.h"
#import "TUIButton.h"
#import "TUITextView.h"
#import "TUITextField.h"
#import "TUIAttributedString.h"
#import "TUIActivityIndicatorView.h"
#import "TUINSView.h"
#import "TUINSWindow.h"
#import "TUIStringDrawing.h"
#import "TUIViewController.h"
#import "TUICGAdditions.h"
#import "CoreText+Additions.h"
#import "TUITextEditor.h"
#import "TUIPopover.h"
#import "CAAnimation+TUIExtensions.h"

extern CGContextRef TUIGraphicsGetCurrentContext(void);
extern void TUIGraphicsPushContext(CGContextRef context);
extern void TUIGraphicsPopContext(void);

extern TUIImage *TUIGraphicsContextGetImage(CGContextRef ctx);

extern void TUIGraphicsBeginImageContext(CGSize size);
extern void TUIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale);
extern TUIImage *TUIGraphicsGetImageFromCurrentImageContext(void);
extern void TUIGraphicsEndImageContext(void); 

extern TUIImage *TUIGraphicsGetImageForView(TUIView *view);

extern TUIImage *TUIGraphicsDrawAsImage(CGSize size, void(^draw)(void));

/**
 Draw drawing as a PDF
 @param optionalMediaBox may be NULL
 @returns NSData encapsulating the PDF drawing, suitable for writing to a file or the pasteboard
 */
extern NSData *TUIGraphicsDrawAsPDF(CGRect *optionalMediaBox, void(^draw)(CGContextRef));

extern BOOL AtLeastLion; // set at launch
