//
//  StepDecoder.h
//  BalanceBeam
//
//  Created by David on 11/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface StepDecoder : NSObject {
  NSMutableArray *a_; // of Step, a private type defined in the .m file.
}
- (void)setData:(float)tr br:(float)br tl:(float)tl bl:(float)bl;

@end
