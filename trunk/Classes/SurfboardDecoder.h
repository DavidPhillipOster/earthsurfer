//
//  SurfboardDecoder.h
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

#import <Foundation/Foundation.h>

@protocol SurfboardDecoderDelegate;

@interface SurfboardDecoder : NSObject {
  id<SurfboardDecoderDelegate> delegate_;
  NSMutableArray *a_; // of Step, a private type defined in the .m file.
  float x_;
  float y_;
  float averageTotalWeight_;
}
- (id<SurfboardDecoderDelegate>)delegate;
- (void)setDelegate:(id<SurfboardDecoderDelegate>)delegate;

- (void)setData:(float)tr br:(float)br tl:(float)tl bl:(float)bl;

- (float)x;
- (float)y;
@end

@protocol SurfboardDecoderDelegate<NSObject>

- (void)currentX:(float)x y:(float)y;

- (void)didJump;

@end