//
//  ContainerView.h
//  EarthSurfer
//   Copyright 2009 Google Inc.
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.

#import <Cocoa/Cocoa.h>

@class BalanceBeamView;
@class CursorShielder;
@class WebView;

// Connect the .nib to accessors.
@interface ContainerView : NSView {
 @private
  CursorShielder *shielder_;
  IBOutlet WebView *webView_;
	IBOutlet BalanceBeamView *bbView_;
  IBOutlet NSProgressIndicator *spinner_;
  IBOutlet NSTextField *prompt_;

  IBOutlet NSTextField *legend_;
  IBOutlet NSButton *searchPrompt_;
  IBOutlet NSButton *searchDisclosure_;
  IBOutlet NSSearchField *searchText_;

  IBOutlet NSTextField *labelA_;  // for debugging
  IBOutlet NSTextField *labelB_;  // for debugging
}
- (NSTextField *)legend;
- (WebView *)webView;
- (BalanceBeamView *)bbView;
- (NSProgressIndicator *)spinner;
- (NSTextField *)prompt;
- (NSButton *)searchDisclosure;
- (NSSearchField *)searchText;

// DEBUG
- (NSTextField *)labelA;
- (NSTextField *)labelB;
@end
