//
//  CursorShielder.m
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

#import "CursorShielder.h"

@interface CursorShielder(Private)

- (void)mouseAtPointInView:(NSPoint)p;


- (void)setShieldTimer:(NSTimer *)timer;
@end


@implementation CursorShielder

- (id)initWithView:(NSView *)view {
  self = [super init];
  if (self) {
    view_ = view;
    [[view window] setAcceptsMouseMovedEvents:YES];
    NSPoint windowPoint = [[view_ window] convertScreenToBase:[NSEvent mouseLocation]];
    NSPoint viewPoint = [view_ convertPoint:windowPoint fromView:nil];
    [self mouseAtPointInView:viewPoint];
  }
  return self;
}


- (void)dealloc {
  [self invalidate];
  [super dealloc];
}

- (void)invalidate {
  view_ = nil;
  [self setShieldTimer:nil];
}

// Input: mouse position in View coordinates.
// * remember the time of last call.
// * if transitioning from outside to inside, start the timer.
// * if transitioning from inside to outside cancel the timer.
- (void)mouseAtPointInView:(NSPoint)p {
  lastMoved_ = [NSDate timeIntervalSinceReferenceDate];
  BOOL isInside = NSPointInRect(p, [view_ bounds]);
  if (isInside != (nil != shieldTimer_)) {
    if (isInside) {
      NSTimer *timer = 
        [NSTimer scheduledTimerWithTimeInterval:0.3 
                                         target:self
                                       selector:@selector(shieldTimer:) 
                                       userInfo:nil 
                                        repeats:YES];
      [self setShieldTimer:timer];
    } else {
      [self setShieldTimer:NO];
    }
  }
}

- (void)mouseMoved:(NSEvent *)event {
  NSPoint p = [view_ convertPoint:[event locationInWindow]  fromView:nil];
  [self mouseAtPointInView:p];
}

// * If mouse hasn't moved for .2 seconds, then hide it until it moves again.
- (void)shieldTimer:(NSTimer *)timer {
  if (0.2 < [NSDate timeIntervalSinceReferenceDate] - lastMoved_) {
    [NSCursor setHiddenUntilMouseMoves:YES];
  }
}

- (void)setShieldTimer:(NSTimer *)timer {
  if (shieldTimer_ != timer) {
    [shieldTimer_ invalidate];
    [shieldTimer_ release];
    shieldTimer_ = [timer retain];
  }
}


@end
