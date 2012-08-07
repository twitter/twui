# TwUI 0.4.0

TwUI is a hardware accelerated UI framework for Mac, inspired by UIKit.  It enables:

* GPU accelerated rendering backed by CoreAnimation
* Simple model/view/controller development familiar to iOS developers

It differs from UIKit in a few ways:

* Simplified table view cells
* Block-based layout and drawRect
* A consistent coordinate system (bottom left origin)
* Sub-pixel text rendering

# Setup

To use the current development version, include all the files in your project and import TUIKit.h. Set your target to link to the ApplicationServices and QuartzCore frameworks.

# Usage

Your `TUIView`-based view hierarchy is hosted inside an `TUINSView`, which is the bridge between AppKit and TwUI.  You may set a `TUINSView` as the content view of your window, if you'd like to build your whole UI with TwUI.  Or you may opt to have a few smaller `TUINSViews`, using TwUI just where it makes sense and continue to use AppKit everywhere else.

You can also add `NSViews` to a TwUI hierarchy using `TUIViewNSViewContainer`, which bridges back into AppKit from TwUI.

# Example Project

An included example project shows off the basic construction of a pure TwUI-based app.  A `TUINSView` is added as the content view of the window, and some `TUIView`-based views are hosted in that.  Within the table view cells, some `NSTextFields` are also added using `TUIViewNSViewContainer`.  It includes a table view and a tab bar (which is a good example of how you might build your own custom controls).

# Status

TwUI is currently shipping in Twitter for Mac and GitHub for Mac, in use 24/7 by many, many users, and has proven itself very stable.

This project follows the [SemVer](http://semver.org/) standard. The API may change in backwards-incompatible ways between major releases.

The goal of TwUI is to build a high-quality UI framework designed specifically for the Mac.  Much inspiration comes from UIKit, but diverging to try new things (i.e. block-based layout and drawRect), and optimizing for Mac-specific interactions is encouraged.

# Contributing

We will happily accept pull requests that meet one of the following criteria:

 1. It fixes some functionality that is already in TwUI. This might be a bug, or something not working as expected.
 2. It's something so basic or important that TwUI really should have it.
 3. It has to integrate with TwUI internals, and so can't easily be done outside of the framework. This one is the most ambiguous, because interesting things may match this criterion, but still be way out of scope. In some cases, a fork might be more appropriate. Use your best judgment.

# Community

TwUI has a mailing list, subscribe by sending an email to <twui@librelist.com>.

# Copyright and License

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
