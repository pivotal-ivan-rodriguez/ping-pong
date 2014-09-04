//
//  ConfettiScreen.h
//  PingPong
//
//  Created by DX169-XL on 2014-09-04.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConfettiScreen : UIView

- (id)initWithFrame:(CGRect)frame win:(BOOL)win;
- (void)stopEmitting;

@end
