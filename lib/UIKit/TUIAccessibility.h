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

typedef uint64_t TUIAccessibilityTraits;

extern TUIAccessibilityTraits TUIAccessibilityTraitNone;
extern TUIAccessibilityTraits TUIAccessibilityTraitButton;
extern TUIAccessibilityTraits TUIAccessibilityTraitLink;
extern TUIAccessibilityTraits TUIAccessibilityTraitSearchField;
extern TUIAccessibilityTraits TUIAccessibilityTraitImage;
extern TUIAccessibilityTraits TUIAccessibilityTraitSelected;
extern TUIAccessibilityTraits TUIAccessibilityTraitPlaysSound;
extern TUIAccessibilityTraits TUIAccessibilityTraitStaticText;
extern TUIAccessibilityTraits TUIAccessibilityTraitSummaryElement;
extern TUIAccessibilityTraits TUIAccessibilityTraitNotEnabled;
extern TUIAccessibilityTraits TUIAccessibilityTraitUpdatesFrequently;


@interface NSObject (TUIAccessibility)

@property (nonatomic, assign) BOOL isAccessibilityElement;
@property (nonatomic, copy) NSString *accessibilityLabel;
@property (nonatomic, copy) NSString *accessibilityHint;
@property (nonatomic, copy) NSString *accessibilityValue;
@property (nonatomic, assign) TUIAccessibilityTraits accessibilityTraits;
@property (nonatomic, assign) CGRect accessibilityFrame;

@end
