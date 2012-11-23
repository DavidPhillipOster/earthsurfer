//
//  ContainerWindowController.m
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
//
#import "ContainerWindowController.h"
#import "AppDelegate.h"
#import "ContainerView.h"
#import <WebKit/WebKit.h>

@interface ContainerWindowController()

- (ContainerView *)containerView;

@end

@implementation ContainerWindowController

- (ContainerView *)containerView {
  return (ContainerView *) [self view];
}

- (WebView *)webView {
  return [[self containerView] webView];
}

- (BalanceBeamView *)bbView {
  return [[self containerView] bbView];
}

- (NSProgressIndicator *)spinner {
  return [[self containerView] spinner];
}

- (NSTextField *)prompt {
  return [[self containerView] prompt];
}

- (NSButton *)searchDisclosure {
  return [[self containerView] searchDisclosure];
}

- (NSSearchField *)searchText {
  return [[self containerView] searchText];
}

- (NSTextField *)legend {
  return [[self containerView] legend];
}

// DEBUG
- (NSTextField *)labelA { return [[self containerView] labelA]; }
- (NSTextField *)labelB { return [[self containerView] labelA]; }

#pragma mark -

- (void)webView:(WebView *)webView
decidePolicyForNavigationAction:(NSDictionary *)actionInformation
                        request:(NSURLRequest *)request
                          frame:(WebFrame *)frame
               decisionListener:(id<WebPolicyDecisionListener>)listener {
  if ([[[request URL] host] hasSuffix:@"cache.pack.google.com"]) {
    NSURL *url = [NSURL URLWithString:@"http://code.google.com/apis/earth/"];
    [listener ignore];
    [[NSWorkspace sharedWorkspace] openURL:url];
    [NSApp performSelector:@selector(terminate:) withObject:self afterDelay:1.0];
  } else {
    [listener use];
  }
}

- (void)delayedLoad:(NSString *)javascriptProgram {
  NSString *result = [[self webView] stringByEvaluatingJavaScriptFromString:javascriptProgram];
  if (0 != [result length]) {
    NSLog(@"Load: %@", result);
  }
}

// the milktruck 3D model
static NSString *modelURL = 
@"'http://sketchup.google.com/3dwarehouse/download?'\n"
"  + 'mid=3c9a1cac8c73c61b6284d71745f1efa9&rtyp=zip&'\n"
"  + 'fn=milktruck&ctyp=milktruck'\n";

// We get called twice: once when the main frame loads, once when the plug-in loads.
// Load our actual Javascript program the second time.
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
  static int count = 0;
  if (2 == ++count) {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *path = [mainBundle pathForResource:@"surfer1" ofType:@"js"];
    NSURL *url = [NSURL fileURLWithPath:path];
    NSMutableString *theJavascriptProgram =
      [NSMutableString stringWithContentsOfURL:url usedEncoding:NULL error:NULL];
    NSRange wholeRange = NSMakeRange(0, [theJavascriptProgram length]);

#if 1
    // surfer 3D model.
    modelURL = @"'http://earthsurfer.googlecode.com/svn/html/data/silvertoy_new.kmz'";
#endif

    [theJavascriptProgram replaceOccurrencesOfString:@"${MODEL_URL}"
                                          withString:modelURL
                                             options:0
                                               range:wholeRange];
    [self performSelector:@selector(delayedLoad:) withObject:theJavascriptProgram afterDelay:0.01];                   
  }
}

- (void)showSearch {
  [[self searchText] setHidden:NO];
  [[self window] makeFirstResponder:[self searchText]];
}

- (void)hideSearch {
    [[self searchText] setHidden:YES];
    [[self window] makeFirstResponder:[self webView]];
}

- (IBAction)toggleSearchDisclosure:(id)sender {
  if ([sender state]) {
    [self showSearch];
  } else {
    [self hideSearch];
  }
}

- (IBAction)revealSearch:(id)sender {
  [[self searchDisclosure] setState:YES];
  [self showSearch];
}


- (IBAction)doSearch:(id)sender {
  NSString *s = [sender stringValue];
  if (0 != [s length]) {
    [sender setStringValue:@""];
    [TheAppDelegate() doSearch:s];
    [[self searchDisclosure] setState:NO];
    [self hideSearch];
  }
}
 


@end
