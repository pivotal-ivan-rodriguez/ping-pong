//
//  Constants.h
//  PingPong
//
//  Created by DX169-XL on 2014-09-03.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Constants : NSObject

//Keys
extern NSString * const kLeftPlayerKey;
extern NSString * const kRightPlayerKey;
extern NSString * const kServerKey;
extern NSString * const kYourServeLeftKey;
extern NSString * const kYourServeRightKey;
extern NSString * const kLastServeLeftKey;
extern NSString * const kLastServeRightKey;

//Messages
extern NSString * const kPointMessage;
extern NSString * const kOpponentPointMessage;
extern NSString * const kResetMessage;
extern NSString * const kWinMessage;
extern NSString * const kLoseMessage;
extern NSString * const kElevenMessage;
extern NSString * const kTwentyOneMessage;
extern NSString * const kMinusOneMessage;
extern NSString * const kChangeStartingServerMessage;

//Multipeer
extern NSString * const kServerServiceType;

@end
