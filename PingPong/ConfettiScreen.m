//
//  ConfettiScreen.m
//  PingPong
//
//  Created by DX169-XL on 2014-09-04.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "ConfettiScreen.h"

@implementation ConfettiScreen {
    __weak CAEmitterLayer *_confettiEmitter;
    CGFloat _decayAmount;
}

- (id)initWithFrame:(CGRect)frame win:(BOOL)win {
    if ((self = [super initWithFrame:frame])) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
        _confettiEmitter = (CAEmitterLayer*)self.layer;
        _confettiEmitter.emitterPosition = CGPointMake(self.bounds.size.width /2, 0);
        _confettiEmitter.emitterSize = self.bounds.size;
        _confettiEmitter.emitterShape = kCAEmitterLayerLine;

        CAEmitterCell *confetti = [CAEmitterCell emitterCell];
        NSString *imageName = win ? @"Confetti" : @"too_sad";
        confetti.contents = (__bridge id)[[UIImage imageNamed:imageName] CGImage];
        confetti.name = @"confetti";
        confetti.birthRate = win ? 100 : 7;
        confetti.lifetime = 5.0;
        confetti.color = [[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0] CGColor];
        confetti.redRange = 0.8;
        confetti.blueRange = 0.8;
        confetti.greenRange = 0.8;

        confetti.velocity = win ? 100 : 120;
        confetti.velocityRange = 50;
        confetti.emissionRange = (CGFloat) M_PI_2;
        confetti.emissionLongitude = (CGFloat) M_PI;
        confetti.yAcceleration = 150;
        confetti.scale = 1.0;
        confetti.scaleRange = 0.2;
        confetti.spinRange = 10.0;
        _confettiEmitter.emitterCells = [NSArray arrayWithObject:confetti];
    }

    return self;
}

+ (Class)layerClass {
    return [CAEmitterLayer class];
}

static NSTimeInterval const kDecayStepInterval = 0.1;

- (void)decayStep {
    _confettiEmitter.birthRate -=_decayAmount;
    if (_confettiEmitter.birthRate < 0) {
        _confettiEmitter.birthRate = 0;
    } else {
        [self performSelector:@selector(decayStep) withObject:nil afterDelay:kDecayStepInterval];
    }
}

- (void)decayOverTime:(NSTimeInterval)interval {
    _decayAmount = (CGFloat) (_confettiEmitter.birthRate /  (interval / kDecayStepInterval));
    [self decayStep];
}

- (void)stopEmitting {
    _confettiEmitter.birthRate = 0.0;
}


@end
