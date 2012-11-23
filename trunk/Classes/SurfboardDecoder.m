//
//  SurfboardDecoder.m
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

#import "SurfboardDecoder.h"
#import "AppDelegate.h"

BOOL IsApproximatelyEqual(double a, double b) {
  const double kEpsilon = 0.01;
  return fabs(a - b) < kEpsilon;
}

@interface Sample : NSObject {
  NSTimeInterval when_;
	float tr_;
	float br_;
	float tl_;
	float bl_;
}
- (NSTimeInterval)when;
- (float)tr;
- (float)br;
- (float)tl;
- (float)bl;

- (id)initWithTR:(float)tr br:(float)br tl:(float)tl bl:(float)bl;
@end


@implementation Sample

- (id)initWithTR:(float)tr br:(float)br tl:(float)tl bl:(float)bl {
  self = [super init];
  if (self) {
    when_ = [NSDate timeIntervalSinceReferenceDate];
    tr_ = tr;
    br_ = br;
    tl_ = tl;
    bl_ = bl;
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%f\n {%4.1f %4.1f\n %4.1f %4.1f}\n\n",
          when_, tl_, tr_, bl_, br_];
}

- (NSTimeInterval)when { return when_; }
- (float)tr { return tr_; }
- (float)br { return br_; }
- (float)tl { return tl_; }
- (float)bl { return bl_; }


@end


@interface SurfboardDecoder()
- (void)initMe;
@end

@implementation SurfboardDecoder

- (id)init {
  self = [super init];
  if (self) {
    [self initMe];
  }
  return self;
}

- (void) dealloc {
  [a_ release];
  [super dealloc];
}

- (void)awakeFromNib {
  [self initMe];
}

- (void)initMe {
  a_ = [[NSMutableArray alloc] init];
}

- (id<SurfboardDecoderDelegate>)delegate {
  return delegate_;
}

- (void)setDelegate:(id<SurfboardDecoderDelegate>)delegate {
  delegate_ = delegate;
}

- (BOOL)hasLiftOff {
  float lightWeight = averageTotalWeight_ * 0.1;
  for (int i = 0; i < [a_ count]; ++i) {
    Sample *sample = [a_ objectAtIndex:i];
    if (([sample tr] + [sample br] + [sample tl] + [sample bl]) < lightWeight) {
      return YES;
    }
  }
  return NO;
}

// keep the 10 most recent data points.
- (void)setData:(float)tr br:(float)br tl:(float)tl bl:(float)bl {
  BOOL justAdded = NO;
  static const int kCount = 30;
  while (kCount < [a_ count]) {
    [a_ removeObjectAtIndex:0];
  }
  NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
  NSTimeInterval lastWhen = 0;
  if (0 < [a_ count]) {
    lastWhen = [[a_ lastObject] when];
  }
  if (0.01 < now - lastWhen) {
    Sample *sample = [[Sample alloc] initWithTR:tr br:br tl:tl bl:bl];
    [a_ addObject:sample];
    [sample release];
    justAdded = YES;
  }
  float totalWeight = tr + br + tl + bl;
  averageTotalWeight_ += (totalWeight)/kCount;
  float x, y;
  if (totalWeight < 5.) {
    x = 0;
    y = 0;
  } else {
    x = ((tr + tl) - (br + bl)) / totalWeight;
    y = ((tr + br) - (tl + bl)) / totalWeight;
  }
  if (! (IsApproximatelyEqual(x, x_) && IsApproximatelyEqual(y,y_))) {
    x_ = x;
    y_ = y;
    [delegate_ currentX:x y:y];
  }
  if (justAdded && 5 < [a_ count]) {
    int j, i = [a_ count];
    averageTotalWeight_ = 0;
    for (j = 0; j < 5; ++j) {
      Sample *sample = [a_ objectAtIndex:--i];
      averageTotalWeight_ += ([sample tr] + [sample br] + [sample tl] + [sample bl]);
    }
    averageTotalWeight_ = averageTotalWeight_ / 5;
    if (10 < averageTotalWeight_ && averageTotalWeight_* 1.5 < totalWeight) {
      Sample *sample = [a_ objectAtIndex:[a_ count]-2];
      float previousTotalWeight = [sample tr] + [sample br] + [sample tl] + [sample bl];
      if (totalWeight < previousTotalWeight && [self hasLiftOff]) {
        [delegate_ didJump];
      }
    }
    averageTotalWeight_ *= 2.2;
    totalWeight *= 2.2;

#if 0 // for DEBUGGING
    NSString *s = [NSString stringWithFormat:@"%5.1f\t%5.1f", averageTotalWeight_, totalWeight];
    printf("=%s\n", [s UTF8String]);
    [TheAppDelegate() setLegend:s];
#endif
  }
}  

- (float)x {
  return x_;
}

- (float)y {
  return y_;
}

@end
