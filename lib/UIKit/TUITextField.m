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

#import "TUITextField.h"
#import "TUIButton.h"
#import "TUITextViewEditor.h"

@interface TUITextFieldEditor : TUITextViewEditor
@end

@implementation TUITextField

@synthesize rightButton;

- (Class)textEditorClass
{
	return [TUITextFieldEditor class];
}


- (void)setDelegate:(id <TUITextViewDelegate>)d
{
	_textFieldFlags.delegateTextFieldShouldReturn = [d respondsToSelector:@selector(textFieldShouldReturn:)];
	_textFieldFlags.delegateTextFieldShouldClear = [d respondsToSelector:@selector(textFieldShouldClear:)];
	_textFieldFlags.delegateTextFieldShouldTabToNext = [d respondsToSelector:@selector(textFieldShouldTabToNext:)];
	[super setDelegate:d];
}

- (BOOL)singleLine
{
	return YES;
}

- (void)_tabToNext
{
	if(_textFieldFlags.delegateTextFieldShouldTabToNext)
		[(id<TUITextFieldDelegate>)delegate textFieldShouldTabToNext:self];
}

- (void)setRightButton:(TUIButton *)b
{
	if(rightButton != b) {
		[rightButton removeFromSuperview];
		rightButton = b;
		rightButton.layout = ^CGRect(TUIView *v) {
			CGRect b = v.superview.bounds;
			return CGRectMake(b.size.width - b.size.height, 0, b.size.height, b.size.height);
		};
		[self addSubview:rightButton];
	}
}

- (void)clear:(id)sender
{
	if(_textFieldFlags.delegateTextFieldShouldClear) {
		if([(id<TUITextFieldDelegate>)delegate textFieldShouldClear:self]) {
			goto doClear;
		}
	} else {
doClear:
		self.text = @"";
	}
}

- (TUIButton *)clearButton
{
	TUIButton *b = [TUIButton button];
	[b setImage:[NSImage imageNamed:@"clear-button.png"] forState:TUIControlStateNormal];
	[b addTarget:self action:@selector(clear:) forControlEvents:TUIControlEventMouseUpInside];
	return b;
}

@end

@implementation TUITextFieldEditor

- (TUITextField *)_textField
{
	return (TUITextField *)view;
}

- (void)insertTab:(id)sender
{
	[[self _textField] _tabToNext];
}

- (void)insertNewline:(id)sender
{
	if([self _textField]->_textFieldFlags.delegateTextFieldShouldReturn)
		[(id<TUITextFieldDelegate>)[self _textField].delegate textFieldShouldReturn:[self _textField]];
	[[self _textField] sendActionsForControlEvents:TUIControlEventEditingDidEndOnExit];
}

- (void)cancelOperation:(id)sender
{
	[[self _textField] clear:sender];
}

@end
