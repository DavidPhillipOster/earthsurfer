//
//  AppDelegate.m
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

#import "AppDelegate.h"
#import "BalanceBeamView.h"
#import "ContainerWindowController.h"
#import "NSString+Replacing.h"
#import <WebKit/WebKit.h>

typedef struct Place {
  float latitude, longitude, heading;
  NSString *name;
} Place;

static Place places[] = {
  {19.912811, -155.892137, 180, @"Hawaii"},
  {48.16690025239105,-16.20067787461129,140.7666938185872, @"Bismark"},
  {11.32074342549742,142.2542994393187,57.1838710633786, @"Trieste"},
  {41.77754529795025,-49.98271480392425,-27.65196478133371, @"Titanic"},
  {-42.54425194632677,173.7122168156901,-35.54230217378915, @"Squid/Whale"},
  {37.423501,-122.086744,90, @"The 'Plex"},
};

#define COUNT_OF(a) (sizeof (a))/(sizeof (*a))


@interface AppDelegate()
- (NSString *)requestUserAgent;

// the window that holds the webView.
-(NSWindow *)webWindow;

- (ContainerWindowController *)winController;
- (WebView *)webView;
- (BalanceBeamView *)bbView;
- (NSProgressIndicator *)spinner;
- (NSTextField *)prompt;
@end

@implementation AppDelegate

- (void)awakeFromNib {
	[[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(expansionPortChanged:)
                                               name:@"WiiRemoteExpansionPortChangedNotification"
                                             object:nil];

	discovery_ = [[WiiRemoteDiscovery alloc] init];

  if (nil == discovery_) {
    NSBeep();
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: NSLocalizedString(@"Requires Bluetooth", @"")];
    [alert setInformativeText: NSLocalizedString(@"Couldn't initialize Bluetooth.", @"")];
    [alert addButtonWithTitle: NSLocalizedString(@"Quit", @"")];
    if (NSAlertFirstButtonReturn == [alert runModal]){
      [NSApp terminate: nil];
    }
  }

  winController_ = [[ContainerWindowController alloc] initWithWindowNibName:@"FullScreenable"];
  NSResponder *nextResponder = [[winController_ window] nextResponder];
  [self setNextResponder:nextResponder];
  [[winController_ titleBarWindow] setNextResponder:self];
  [[winController_ window] setNextResponder:self];
  [[winController_ window] makeKeyAndOrderFront:self];

//  [self clearCache:nil];  // TODO: comment this out once we are stable.
  WebFrame *mainFrame = [[self webView] mainFrame];
  NSURL *url = [NSURL URLWithString:@"http://earthsurfer.googlecode.com/svn/html/surfer1.html#geplugin_browserok"];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  NSString *requestUserAgent = [self requestUserAgent];
  [request setValue:requestUserAgent forHTTPHeaderField:@"User-Agent"];
  [mainFrame loadRequest:request];



	[discovery_ setDelegate:self];
	[discovery_ start];
	[[self prompt] setStringValue:NSLocalizedString(@"Press the red button", @"")];
	[[self spinner] startAnimation:self];
  surfboardDecoder_ = [[SurfboardDecoder alloc] init];
  [surfboardDecoder_ setDelegate:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  [self toggleFullScreen:nil];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  isShuttingDown_ = YES;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[wii_ closeConnection];
	[wii_ release]; wii_ = nil;
	[discovery_ release]; discovery_ = nil;
	return NSTerminateNow;
}  

- (void) dealloc {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self];
  isShuttingDown_ = YES;
	[wii_ release];
	[discovery_ release];
  [winController_ release];
	[super dealloc];
}


- (void)expansionPortChanged:(NSNotification *)nc{
  
	WiiRemote* tmpWii = (WiiRemote*)[nc object];
	
	// Check that the Wiimote reporting is the one we're connected to.
	if (![[tmpWii address] isEqualToString:[wii_ address]]){
		return;
	}
	[[self prompt] setStringValue:NSLocalizedString(@"Connected", @"")];
		
	if ([wii_ isExpansionPortAttached]){
		[wii_ setExpansionPortEnabled:YES];
	}	
}

- (void) wiiRemoteDisconnected:(IOBluetoothDevice*)device {

	[wii_ release];
	wii_ = nil;
	[discovery_ stop];
  if (! isShuttingDown_) {
    isBalanceBeamCalibrated_ = NO;
    [[self spinner] stopAnimation:self];
    [[self spinner] startAnimation:self];
    [[self prompt] setStringValue:NSLocalizedString(@"Lost connection with Balance Beam. "
     "Please press the red button inside the Balance Beam battery compartment again.", @"")];
    [discovery_ start];
  }
}

- (void) buttonChanged:(WiiButtonType) type isPressed:(BOOL) isPressed {
  if (0 == type) {
    if ([[self bbView] buttonOn] && !isPressed) {
      // making transition from on to off.
      [self nextTeleport:self];
    }
    [[self bbView] setButtonOn:isPressed];
  }
}

- (void) batteryLevelChanged:(double) level {
  NSLog(@"batteryLevelChanged:%g", level);
}


- (void) balanceBeamChangedTopRight:(int)topRight
                        bottomRight:(int)bottomRight
                            topLeft:(int)topLeft
                         bottomLeft:(int)bottomLeft {
	if (!isBalanceBeamCalibrated_) {
		[[self bbView] setData:topRight br:bottomRight tl:topLeft bl:bottomLeft];
	}
}

- (void) balanceBeamKilogramsChangedTopRight:(float)topRight
                                 bottomRight:(float)bottomRight
                                     topLeft:(float)topLeft
                                  bottomLeft:(float)bottomLeft {
  if ( ! isBalanceBeamCalibrated_) {
    isBalanceBeamCalibrated_ = YES;
  }
	
	[[self bbView] setData:topRight br:bottomRight tl:topLeft bl:bottomLeft];
  [surfboardDecoder_ setData:topRight br:bottomRight tl:topLeft bl:bottomLeft];
}

#pragma mark -
#pragma mark ## WiiRemoteDiscoveryDelegate

- (void) WiiRemoteDiscoveryError:(int)code {
	[[self spinner] stopAnimation:self];
  NSString *prompt = [NSString stringWithFormat:@"%@: %d. %@",
    NSLocalizedString(@"Discovery error", @""), code,
    NSLocalizedString(@"Press the red button again", @"")];
	[[self prompt] setStringValue:prompt];
  [self wiiRemoteDisconnected:nil];
}

- (void) willStartWiimoteConnections {
	[[self prompt] setStringValue:NSLocalizedString(@"Balance Beam found", @"")];
}

- (void) WiiRemoteDiscovered:(WiiRemote*)wiimote {
	
	//	[discovery stop];
	
	// The wiimote must be retained because the discovery provides us with an autoreleased object
	[wii_ release];
	wii_ = [wiimote retain];
	[wiimote setDelegate:self];
	
	[[self prompt] setStringValue:NSLocalizedString(@"Connected", @"")];
	[[self spinner] stopAnimation:self];
  [[self webWindow] makeKeyAndOrderFront:self];
}

- (NSWindow *)webWindow {
  return [[self webView] window];
}

- (WebView *)webView {
  WebView *webView = [[self winController] webView];
  return webView;
}

- (ContainerWindowController *)winController {
  return winController_;
}

- (void)setWinController:(ContainerWindowController *)winController {
  [winController_ autorelease];
  winController_ = [winController retain];
}


- (BalanceBeamView *)bbView {
  BalanceBeamView *bbView = [[self winController] bbView];
  return bbView;
}

- (NSProgressIndicator *)spinner {
  NSProgressIndicator *spinner = [[self winController] spinner];
  return spinner;
}

- (NSTextField *)prompt {
  NSTextField *prompt = [[self winController] prompt];
  return prompt;
}


#pragma mark -
#pragma mark ## IBAction

- (NSString *)appVersion {
  NSBundle *mainBundle = [NSBundle mainBundle];
  return [mainBundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
}

- (NSString *)requestUserAgent {
  return [NSString stringWithFormat:@"Searthboard OSX/%@", [self appVersion]];
}


// Given a Javscript global variable of type boolean, set it to true for n
// seconds, then set it to false.
- (void)press:(NSString *)global for:(double)seconds {
  NSString *trueString = [NSString stringWithFormat:@"%@ = true", global];
  NSString *falseString = [NSString stringWithFormat:@"%@ = false", global];
  NSString *result = [[self webView] stringByEvaluatingJavaScriptFromString:trueString];
  if (0 != [result length]) {
  }
  [[self webView] performSelector:@selector(stringByEvaluatingJavaScriptFromString:)
                 withObject:falseString afterDelay:seconds];
}


- (IBAction)moveLeft:(id)sender {
  [self press:@"leftButtonDown" for:0.25];
}

- (IBAction)moveRight:(id)sender {
  [self press:@"rightButtonDown" for:0.25];
}

- (IBAction)moveFaster:(id)sender {
  [self press:@"gasButtonDown" for:0.25];
}

- (IBAction)moveSlower:(id)sender {
  [self press:@"reverseButtonDown" for:0.25];
}

- (NSString *)commandString:(NSString *)string {
NSLog(@"x:%f y%f", xFloat_, yFloat_);
  return [NSString stringWithFormat:@"%@ xLevel=%f; yLevel=%f;",string, xFloat_, yFloat_];
}

- (IBAction)startLeft:(id)sender {
  NSString *result = [[self webView] stringByEvaluatingJavaScriptFromString:
    [self commandString:@"leftButtonDown = true; rightButtonDown = false;"]];
  if (0 != [result length]) {
  }
}

- (IBAction)startRight:(id)sender {
  [[self webView] stringByEvaluatingJavaScriptFromString:
    [self commandString:@"leftButtonDown = false; rightButtonDown = true;"]];
}

- (IBAction)startFaster:(id)sender {
  [[self webView] stringByEvaluatingJavaScriptFromString:
    [self commandString:@"gasButtonDown = true; reverseButtonDown = false;"]];
}

- (IBAction)startSlower:(id)sender {
  [[self webView] stringByEvaluatingJavaScriptFromString:
    [self commandString:@"gasButtonDown = false; reverseButtonDown = true;"]];
}


- (IBAction)stopLeft:(id)sender {
  [[self webView] stringByEvaluatingJavaScriptFromString:
    [self commandString:@"leftButtonDown = false;"]];
}

- (IBAction)stopRight:(id)sender {
  [[self webView] stringByEvaluatingJavaScriptFromString:
    [self commandString:@"rightButtonDown = false;"]];
}

- (IBAction)stopFaster:(id)sender {
  [[self webView] stringByEvaluatingJavaScriptFromString:
    [self commandString:@"gasButtonDown = false;"]];
}

- (IBAction)stopSlower:(id)sender {
  [[self webView] stringByEvaluatingJavaScriptFromString:
    [self commandString:@"reverseButtonDown = false;"]];
}

- (IBAction)jump:(id)sender {
  [[self webView] stringByEvaluatingJavaScriptFromString:
    [self commandString:@"jumpButtonSignalled = true;"]];
}


- (void)currentX:(float)x y:(float)y {
  int dx;
  int dy;
  if (x < -0.2) {
    dx = -1;
  } else if (0.2 < x) {
    dx = 1;
  } else {
    dx = 0;
  }

  if (y < -0.2) {
    dy = -1;
  } else if (0.2 < y) {
    dy = 1;
  } else {
    dy = 0;
  }
  xFloat_ = x;
  yFloat_ = y;
  if (dx != x_) {
    switch (dx) {
      case -1:
//NSLog(@"%f %f %d %d %@", x, y, dx, dy, @"startRight");
        [self startRight:self];
        break;
      default: 
      case 0:
//NSLog(@"%f %f %d %d %@", x, y, dx, dy, @"stopRight/left");
        [self stopRight:self];
        [self stopLeft:self];
        break;
      case 1:
//NSLog(@"%f %f %d %d %@", x, y, dx, dy, @"startLeft");
        [self startLeft:self];
        break;
    }
    x_ = dx;
  }
  if (dy != y_) {
    switch (dy) {
      case -1:
//NSLog(@"%f %f %d %d %@", x, y, dx, dy, @"startSlower");
        [self startSlower:self];
        break;
      default: 
      case 0:
//NSLog(@"%f %f %d %d %@", x, y, dx, dy, @"stopSlower/stopFaster");
        [self stopSlower:self];
        [self stopFaster:self];
        break;
      case 1:
//NSLog(@"%f %f %d %d %@", x, y, dx, dy, @"startFaster");
        [self startFaster:self];
        break;
    }
    y_ = dy;
  }

}



- (IBAction)clearCache:(id)sender {
  [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (IBAction)toggleFullScreen:(id)sender {
  [winController_ toggleFullScreen];
}

- (void)keyDown:(NSEvent *)theEvent {
  static NSString *escape = nil;
  if (nil == escape) {
    escape = [[NSString stringWithFormat:@"%c", 27] retain];
  }
  if ([[theEvent characters] isEqual:escape]) {
    [winController_ setFullScreen:NO];
  } else {
    [super keyDown:theEvent];
  }
}

// Default binding of escape key.
- (void)complete:(id)sender {
  [winController_ setFullScreen:NO];
}

// Default binding of Command-period.
- (void)cancelOperation:(id)sender {
  [winController_ setFullScreen:NO];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  return YES;
}

- (IBAction)nextTeleport:(id)sender {
  ++teleportIndex_;
  if (COUNT_OF(places) <= teleportIndex_) {
    teleportIndex_ = 0;
  }
  NSString *s = [NSString stringWithFormat:@"truck.teleportTo(%f,%f,%f)",
    places[teleportIndex_].latitude, places[teleportIndex_].longitude, places[teleportIndex_].heading];
  NSString *result = [[self webView] stringByEvaluatingJavaScriptFromString:s];
  if (0 != [result length]) {
  }
  [self setLegend:places[teleportIndex_].name];
}

- (IBAction)doSearch:(NSString *)s {
  NSArray *recentSearches = [[winController_ searchText] recentSearches];
  if (![recentSearches containsObject:s]) {
    NSMutableArray *newSearches = [[recentSearches mutableCopy] autorelease];
    if (nil == newSearches) {
      newSearches = [NSMutableArray array];
    }
    [newSearches insertObject:s atIndex:0];
    [[winController_ searchText] setRecentSearches:newSearches];
  }
  NSString *stringifiedS = [[s stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"] 
    stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
  NSString *teleportSearch = [NSString stringWithFormat:@"doGeocode(\"%@\")", stringifiedS];
  NSString *result = [[self webView] stringByEvaluatingJavaScriptFromString:teleportSearch];
  if (0 != [result length]) {
// TODO: ?
  }
  [self setLegend:s];
}

- (void)setLegend:(NSString *)legend {
  [[winController_ legend] setStringValue:legend];
}


- (void)jumpEnd:(NSTimer *)timer {
  [[winController_ labelB] setStringValue:@""];
}

- (void)didJump {
  [stopJump_ invalidate];
  [stopJump_ release];
  stopJump_ = [[NSTimer scheduledTimerWithTimeInterval:0.8 target:self selector:@selector(jumpEnd:) userInfo:nil repeats:NO] retain];
  [[winController_ labelB] setStringValue:@"#JUMP#\n"];
  [self jump:self];
}

@end

AppDelegate *TheAppDelegate(void) {
  static AppDelegate *sAppDelegate = nil;
  if (nil == sAppDelegate) {
    sAppDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
  }
  return sAppDelegate;
}


