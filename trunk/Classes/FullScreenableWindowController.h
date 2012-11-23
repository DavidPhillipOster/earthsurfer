//
//  FullScreenableWindowController.h
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

#import <Cocoa/Cocoa.h>
// Since are window has no title bar, the default values for these methods break.
@interface FullScreenableWindow : NSWindow {
}
@end

// Given a view in a window, move the view to a fullscreen window or back to
// the original window, depending on the state of the isFullScreen BOOL.
//
// Additional complexity: the Google Earth Browser Plugin does not like its
// owning webview to move from window to window, so I had to find a way to go
// from a semi-normal state to a full screen state in the same window.
// I did it by using parent and child windows, where the parent window is just a title bar.
@interface FullScreenableWindowController : NSWindowController<NSWindowDelegate> {
 @private
  IBOutlet NSWindow *titleBarWindow_;
  IBOutlet NSView *view_;
  BOOL isFullScreen_;

  // holds state while app is not active.
  BOOL lastActiveIsFullScreen_;


  // holds normal window state of view, while full screen.
  NSRect  normalFrame_;

  // For sizeChanged
  NSRect initialGrowTitleFrame_;
  NSRect initialGrowFrame_;

  // for zoom to full screen (with menu bar)
  NSSize titleBarWindowStandardZoomSize_;
  NSRect windowNormalZoomFrame_;
}
@property (nonatomic, retain) NSWindow *titleBarWindow;
@property (nonatomic, retain) NSView *view;

- (NSWindow *)titleBarWindow;

- (NSView *)view;
- (void)setView:(NSView *)view;

- (BOOL)isFullScreen;
- (void)setFullScreen:(BOOL)isFullScreen;

- (void)toggleFullScreen; // convenience

// Used internally
- (void)sizeChangedStart;
- (void)sizeChanged:(NSPoint)delta;

@end
