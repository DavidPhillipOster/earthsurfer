//
//  BalanceBeamView.m
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

#import "BalanceBeamView.h"
#import "NSImage+Rotate.h"

@interface BalanceBeamView()
@end

@implementation BalanceBeamView


- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    if ([self isLandscape]) {
      center_ = NSMakePoint(85, 48);
    } else {
      center_ = NSMakePoint(48, 85);
    }
  }
  return self;
}

- (void)dealloc {
	[bb0_ release];
	[bb30_ release];
	[bb100_ release];
	[super dealloc];
}

- (void)awakeFromNib {
  float degrees = [self isLandscape] ? 0.0 : 90.0;
	bb0_ = [[[NSImage imageNamed:@"bb0"] imageRotated:degrees] retain];
	bb30_ = [[[NSImage imageNamed:@"bb30"] imageRotated:degrees] retain];
	bb100_ = [[[NSImage imageNamed:@"bb100"] imageRotated:degrees] retain];
}

- (void)imageLo:(NSImage *)lowImage imageHi:(NSImage *)highImage value:(float)value max:(float)max rect:(NSRect)rect {
	float alpha = fmax(value, 0)/max;
	[highImage drawInRect:rect fromRect:rect operation: NSCompositeSourceOver fraction:alpha];
	[lowImage drawInRect:rect fromRect:rect operation: NSCompositeSourceOver fraction:1. - alpha];
}


- (void)drawRect:(NSRect)rect {
	NSRect bounds = [self bounds];
  [bb0_ compositeToPoint:NSMakePoint(0, 0) operation:NSCompositeSourceOver];

	NSRect tlRect = NSMakeRect(0, center_.y, center_.x, bounds.size.height - center_.y);
	NSRect blRect = NSMakeRect(0, 0, center_.x, center_.y);
	NSRect trRect = NSMakeRect(center_.x, center_.y, bounds.size.width - center_.x, bounds.size.height - center_.y);
	NSRect brRect = NSMakeRect(center_.x, 0, bounds.size.width - center_.x, center_.y);

  if (![self isLandscape]) {
    NSRect t = tlRect;
    tlRect = blRect;
    blRect = brRect;
    brRect = trRect;
    trRect = t;
  }
  
	if (tl_ < 30.) {
		[self imageLo:bb0_ imageHi:bb30_ value:tl_ max:30. rect:tlRect];
	} else {
		[self imageLo:bb30_ imageHi:bb100_ value:tl_ - 30. max:70. rect:tlRect];
	}
	
	if (bl_ < 30.) {
		[self imageLo:bb0_ imageHi:bb30_ value:bl_ max:30. rect:blRect];
	} else {
		[self imageLo:bb30_ imageHi:bb100_ value:bl_ - 30. max:70. rect:blRect];
	}
	
	if (tr_ < 30.) {
		[self imageLo:bb0_ imageHi:bb30_ value:tr_ max:30. rect:trRect];
	} else {
		[self imageLo:bb30_ imageHi:bb100_ value:tr_ - 30. max:70. rect:trRect];
	}

	if (br_ < 30.) {
		[self imageLo:bb0_ imageHi:bb30_ value:br_ max:30. rect:brRect];
	} else {
		[self imageLo:bb30_ imageHi:bb100_ value:br_ - 30. max:70. rect:brRect];
	}
  if (isOn_) {
    NSRect buttonRect;
    if ([self isLandscape]) {
      buttonRect = NSMakeRect(center_.x - 7, 5, 12, 3);
    } else {
      NSRect bounds = [self bounds];
      buttonRect = NSMakeRect(bounds.size.width - 7, center_.y - 7, 3, 12);
    }
    [[NSColor greenColor] set];
    [NSBezierPath fillRect:buttonRect];
  }
}

- (void)setData:(float)tr br:(float)br tl:(float)tl bl:(float)bl {
	if (! (tr_ == tr && br_ == br && tl_ == tl && bl_ == bl) ) {
		tr_ = tr;
		br_ = br;
		tl_ = tl;
		bl_ = bl;
		[self setNeedsDisplay:YES];
	}
}

- (BOOL)buttonOn {
  return isOn_;
}


- (void)setButtonOn:(BOOL)isOn {
  if (isOn != isOn_) {
    isOn_ = isOn;
		[self setNeedsDisplay:YES];
  }
}

- (BOOL)isLandscape {
  NSSize size = [self frame].size;
  return size.height < size.width;
}


@end
