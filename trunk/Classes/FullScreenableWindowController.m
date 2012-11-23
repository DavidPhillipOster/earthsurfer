//
//  FullScreenableWindowController.m
//  FullScreen
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
//

#import "FullScreenableWindowController.h"
#import <Carbon/Carbon.h>

// Since are window has no title bar, the default values for these methods break.
@interface FullScreenableWindow : NSWindow {
}
@end

@implementation FullScreenableWindow

// Borderless NSWindows return NO, so we subclass. 
- (BOOL)acceptsFirstResponder {
  return YES;
}

// Borderless NSWindows return NO, so we subclass. 
- (BOOL)canBecomeKeyWindow {
  return YES;
}

// Borderless NSWindows return NO, so we subclass. 
- (BOOL)canBecomeMainWindow {
  return YES;
}

- (NSRect)growRect {
  NSRect bounds = [[self contentView] bounds];
  bounds.size.height = 16;
  bounds.origin.x += bounds.size.width - 16;
  bounds.size.width = 16;
  return bounds;
}

// During grow drag, the window's origin changes. We use this to compensate.
- (NSPoint)locationInScreen:(NSPoint)p {
  NSPoint origin = [self frame].origin;
  return NSMakePoint(p.x + origin.x, p.y + origin.y);
}

- (void)mouseDown:(NSEvent *)theEvent {
  if (NSPointInRect([theEvent locationInWindow], [self growRect])) {
    NSPoint initialPoint = [self locationInScreen:[theEvent locationInWindow]];
    [(FullScreenableWindowController *)[self delegate] sizeChangedStart];
    for (;;) {
      NSEvent *event = [self nextEventMatchingMask:NSLeftMouseDraggedMask|NSLeftMouseUpMask];
      if (NSLeftMouseDragged != [event type]) {
        break;  // <-- loop exit
      }
      NSPoint newPoint = [self locationInScreen:[event locationInWindow]];
      NSPoint deltaPoint = NSMakePoint(newPoint.x - initialPoint.x, newPoint.y - initialPoint.y);
      [(FullScreenableWindowController *)[self delegate] sizeChanged:deltaPoint];
    }
  } else {
    [super mouseDown:theEvent];
  }
}

- (void)fullScreen_setValueFrame:(NSValue *)vFrame {
  NSRect frame = [vFrame rectValue];
  [self setFrame:frame display:YES animate:NO];
}

@end

@interface FullScreenableWindowController()
- (void)initCommon;
- (void)doFullScreen;
- (void)doNormalWindow;
@end

@implementation FullScreenableWindowController

- (id)initWithWindow:(NSWindow *)window {
  self = [super initWithWindow:window];
  [self initCommon];
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  [self initCommon];
  return self;
}


- (void)initCommon {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(applicationWillResignActive:) name:NSApplicationWillResignActiveNotification object:NSApp];
  [nc addObserver:self selector:@selector(applicationWillBecomeActive:) name:NSApplicationWillBecomeActiveNotification object:NSApp];
  [nc addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:NSApp];
  [nc addObserver:self selector:@selector(applicationDidChangeScreenParameters:) name:NSApplicationDidChangeScreenParametersNotification object:NSApp];
}


- (void)dealloc {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self];
  [view_ release];
  [titleBarWindow_ release];
  [super dealloc];
}

- (void)awakeFromNib {
  NSRect frame = [[self window] frame];
  titleBarWindow_ = [self window];
  [titleBarWindow_ setDelegate:self];
  [titleBarWindow_ setHasShadow:NO];
  [titleBarWindow_ setShowsResizeIndicator:NO];
  FullScreenableWindow *fullScreenableWindow =
    [[[FullScreenableWindow alloc] initWithContentRect:frame
                                  styleMask:NSBorderlessWindowMask
                                    backing:NSBackingStoreBuffered
                                      defer:YES] autorelease];
  [fullScreenableWindow setDelegate:self];
  [fullScreenableWindow setFrameUsingName:@"Earth-Surfer"];
  [self setWindow:fullScreenableWindow];
  [view_ removeFromSuperviewWithoutNeedingDisplay];
  [[[self window] contentView] addSubview:view_];
  frame = [fullScreenableWindow frame];
  frame.origin.y += (frame.size.height - 20.);
  frame.size.height = 20.;
  [titleBarWindow_ setFrame:frame display:YES];
  [titleBarWindow_ addChildWindow:[self window] ordered:NSWindowBelow];
  [titleBarWindow_ makeKeyAndOrderFront:self];
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
         selector:@selector(FullScreenableWindowWillClose:)
             name:NSWindowWillCloseNotification
           object:titleBarWindow_];
}

#pragma mark -

- (NSWindow *)titleBarWindow {
  return titleBarWindow_;
}


- (NSView *)view {
  return view_;
}

- (void)setView:(NSView *)view {
  [view_ autorelease];
  view_ = [view retain];
  normalFrame_ = [view_ frame];
}


- (BOOL)isFullScreen {
  return isFullScreen_;
}

- (void)setFullScreen:(BOOL)isFullScreen {
  if ([self isFullScreen] != isFullScreen) {
    if (isFullScreen) {
      [self doFullScreen];
    } else {
      [self doNormalWindow];
    }
    isFullScreen_ = isFullScreen;
  }
}

- (void)toggleFullScreen {
  [self setFullScreen:![self isFullScreen]];
}

- (void)sizeChangedStart {
  if (![self isFullScreen]) {
    initialGrowTitleFrame_ = [titleBarWindow_ frame];
    initialGrowFrame_ = [[self window] frame];
  }
}


- (void)sizeChanged:(NSPoint)delta {
  if (![self isFullScreen] && (0. != delta.x || 0. != delta.y)) {
    NSRect frame = initialGrowFrame_;

    float newHeight = MAX(frame.size.height + delta.y, 60.);
    float deltaHeight = newHeight - frame.size.height;

    frame.size.width = MAX(frame.size.width + delta.x, 60.);
    frame.origin.y += deltaHeight;
    frame.size.height -= deltaHeight;

    [[self window] setFrame:frame display:YES animate:NO];

    if (0. != delta.x) {
      frame = initialGrowTitleFrame_;
      frame.size.width = MAX(frame.size.width + delta.x, 60.);
      [titleBarWindow_ setFrame:frame display:YES];
    }
  }
}


- (void)FullScreenableWindowWillClose:(NSNotification *)notify {
  [[self window] close];
}

#pragma mark -

- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)frameSize {
  if (window == titleBarWindow_ && NSEqualSizes([titleBarWindow_ frame].size, titleBarWindowStandardZoomSize_)) {
    [[self window] performSelector:@selector(fullScreen_setValueFrame:) withObject:[NSValue valueWithRect:windowNormalZoomFrame_] afterDelay:0.01];
  }
  return frameSize;
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame {
  if (window == titleBarWindow_) {
    float targetHeight = [titleBarWindow_ frame].size.height;
    NSRect bodyFrame = newFrame;
    newFrame.origin.y += newFrame.size.height - targetHeight;
    newFrame.size.height = targetHeight;
    if (!NSEqualSizes(titleBarWindowStandardZoomSize_, newFrame.size)) {
      titleBarWindowStandardZoomSize_ = newFrame.size;
      windowNormalZoomFrame_ = [[self window] frame];
    }

    bodyFrame.size.height -= targetHeight;
    [[self window] performSelector:@selector(fullScreen_setValueFrame:) withObject:[NSValue valueWithRect:bodyFrame] afterDelay:0.01];
  }
  return newFrame;
}

- (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)newFrame {
  return YES;
}



#pragma mark -

// If the application is hidden, it will also resign active.
- (void)applicationWillResignActive:(NSNotification *)notify {
  lastActiveIsFullScreen_ = [self isFullScreen];
  [self setFullScreen:NO];
}

- (void)applicationWillBecomeActive:(NSNotification *)notify {
  [self setFullScreen:lastActiveIsFullScreen_];
}

- (void)applicationWillTerminate:(NSNotification *)notify {
  [self setFullScreen:NO];
  [[self window] saveFrameUsingName:@"Earth-Surfer"];
}

- (void)applicationDidChangeScreenParameters:(NSNotification *)notify {
  if ([self isFullScreen]) {
    NSView *contentView = [[self window] contentView];
    [view_ setFrame:[contentView bounds]];
  }
}

#pragma mark -

- (void)doFullScreen {
  SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
  NSRect frame = [[NSScreen mainScreen] frame];
  frame.size.height += 24;
  normalFrame_ = [[self window] frame];
  [[self window] setFrame:frame display:YES];
  NSView *contentView = [[self window] contentView];
  [contentView setNeedsDisplay:YES];
  [titleBarWindow_ removeChildWindow:[self window]];
  [titleBarWindow_ orderOut:self];
  [[self window] makeKeyAndOrderFront:self];
}

- (void)doNormalWindow {
  SetSystemUIMode(kUIModeNormal, 0);
  [[self window] setFrame:normalFrame_  display:YES];
  [titleBarWindow_ orderFront:self];
  [titleBarWindow_ addChildWindow:[self window] ordered:NSWindowBelow];
  [titleBarWindow_ makeKeyAndOrderFront:self];
  NSView *contentView = [[self window] contentView];
  [contentView setNeedsDisplay:YES];
}

@end
