//
//  CursorShielder.h
//  TrackingRect
//
//  Created by David Phillip Oster on 4/2/09.
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
//

#import <Cocoa/Cocoa.h>

// helper object for a view, to hide the mouse cursor when it is over the view, but not moving.
// See the readme file in this directory for more information.

// Requires that owning view implement
// mouseMoved:(NSEvent *)e { [shield_ mouseMoved:e]; [super mouseMoved:e]; }
//
@interface CursorShielder : NSObject {
  NSTimer *shieldTimer_;
  NSView *view_;  // WEAK (since view owns us, strong would make a cycle.)
  NSTimeInterval lastMoved_;
}
- (id)initWithView:(NSView *)view;

// Disconnect. make non-functional.
- (void)invalidate;

- (void)mouseMoved:(NSEvent *)event;
@end
