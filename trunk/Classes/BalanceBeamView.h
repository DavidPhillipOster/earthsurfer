//
//  BalanceBeamView.h
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


@interface BalanceBeamView : NSView {
	NSImage *bb0_;
	NSImage *bb30_;
	NSImage *bb100_;
	NSPoint center_;
	float tr_;
	float br_;
	float tl_;
	float bl_;
  BOOL isOn_;
}
- (void)setData:(float)tr br:(float)br tl:(float)tl bl:(float)bl;

- (void)setButtonOn:(BOOL)isOn;
- (BOOL)buttonOn;

// View is in portrait mode if taller than wide.
// data values are always in landscape coordinates
- (BOOL)isLandscape;

@end
