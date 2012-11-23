//
//  StepDecoder.m
//  BalanceBeam
//
//  Created by David on 11/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "StepDecoder.h"
#import "AppDelegate.h"

typedef enum StepKind {
  kNoStep = 0,
  kForwardStep = (1 << 0),
  kBackStep = (1 << 1),
  kRightStep = (1 << 2),
  kLeftStep = (1 << 3),
  kUpStep = (1 << 4),
  kDownStep = (1 << 5),
} StepKind;



@interface Step : NSObject {
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
- (StepKind)stepKind;
@end

@implementation Step

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


- (StepKind)stepKind {
  float sum = tl_ + tr_ + bl_ + br_;
  if (sum < 5.) {
    return kNoStep;
  }
  // rescale so corners sum to 1.
  float tl = tl_ / sum;
  float tr = tr_ / sum;
  float bl = bl_ / sum;
  float br = br_ / sum;
  if (0.8 < tl + bl) {  // 2 left pads have most of the weight
    return kForwardStep;
  }
  if (0.8 < tr + br) { // 2 right pads have most of the weight
    return kForwardStep;
  }
  if (0.7 < tl + br) {
    return kRightStep;
  }
  if (0.7 < tr + bl) {
    return kLeftStep;
  }
  if (0.8 < tl + tr) {
    return kDownStep;
  }
  if (0.8 < bl + br) {
    return kUpStep;
  }
  return kNoStep;
}

- (NSTimeInterval)when { return when_; }
- (float)tr { return tr_; }
- (float)br { return br_; }
- (float)tl { return tl_; }
- (float)bl { return bl_; }


@end



@interface StepDecoder()

- (void)initMe;

- (StepKind)analyzeStep;

@end

@implementation StepDecoder

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

- (StepKind)analyzeStep {
  if (8 <= [a_ count]) {
    StepKind value = [[a_ objectAtIndex:[a_ count] - 1] stepKind];
    StepKind valueMinus1 = [[a_ objectAtIndex:[a_ count] - 2] stepKind];
    if (value != valueMinus1) {
      return value;
    }
  }
  return kNoStep;
}

// keep the 10 most recent data points.
- (void)setData:(float)tr br:(float)br tl:(float)tl bl:(float)bl {
  while (30 < [a_ count]) {
    [a_ removeObjectAtIndex:0];
  }
  NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
  NSTimeInterval lastWhen = 0;
  if (0 < [a_ count]) {
    lastWhen = [[a_ lastObject] when];
  }
  if (0.01 < now - lastWhen) {
    Step *step = [[Step alloc] initWithTR:tr br:br tl:tl bl:bl];
    [a_ addObject:step];
    [step release];
  }

  StepKind stepKind = [self analyzeStep];
  if (stepKind == kNoStep) {
  } else {
    if (stepKind & kForwardStep) {
    } else if (stepKind & kBackStep) {
    } else if (0 == (stepKind & (kForwardStep|kBackStep))) {
    }
    if (stepKind & kLeftStep) {
    } else if (stepKind & kRightStep) {
    } else if (0 == (stepKind & (kLeftStep|kRightStep))) {
    }
  }
}

@end
