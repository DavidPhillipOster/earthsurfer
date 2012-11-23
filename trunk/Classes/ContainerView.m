//
//  ContainerView.m
//  EarthSurfer
//
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

#import "ContainerView.h"
#import "AppDelegate.h"
#import "CursorShielder.h"
#import <WebKit/WebKit.h>


@implementation ContainerView

- (void)awakeFromNib {
  [labelA_ setStringValue:@""];
  [labelB_ setStringValue:@""];
  shielder_ = [[CursorShielder alloc] initWithView:self];
}

- (void)dealloc {
  [shielder_ release];
  [webView_ release];
  [bbView_ release];
  [spinner_ release];
  [prompt_ release];
  [searchPrompt_ release];
  [searchDisclosure_ release];
  [searchText_ release];
  [super dealloc];
}

// shield_ support
- (void)mouseMoved:(NSEvent *)e {
  [shielder_ mouseMoved:e];
  [super mouseMoved:e];
}

- (NSTextField *)legend { return legend_; }
- (WebView *)webView { return webView_; }
- (BalanceBeamView *)bbView { return bbView_; }
- (NSProgressIndicator *)spinner { return spinner_; }
- (NSTextField *)prompt { return prompt_; }
- (NSButton *)searchDisclosure { return searchDisclosure_; }
- (NSSearchField *)searchText { return searchText_; }

// DEBUG
- (NSTextField *)labelA { return labelA_; }
- (NSTextField *)labelB { return labelB_; }

@end
