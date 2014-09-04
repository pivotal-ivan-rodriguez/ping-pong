//
//  MultipeerManager.h
//  PingPong
//
//  Created by DX169-XL on 2014-09-03.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MCBrowserViewController;

@protocol MultipeerServerDelegate <NSObject>

- (void)leftPlayerScored;
- (void)rightPlayerScored;
- (void)setupLeftImage:(UIImage *)image;
- (void)setupRightImage:(UIImage *)image;
- (void)clientTriggeredReset;
- (void)setupGameWithPointsToWin:(NSInteger)pointsToWin;
- (void)minusOneToLeftScore;
- (void)minusOneToRightScore;
- (void)didStartDownloadingPhoto;
- (void)photoDownloadPercent:(CGFloat)percent;
- (void)leftPlayerConnected;
- (void)rightPlayerConnected;
- (void)leftPlayerDisconnected;
- (void)rightPlayerDisconnected;
- (void)serverConnected;
- (void)serverDisconnected;
- (void)changeStartingServer;

@end

@protocol MultipeerClientDelegate <NSObject>


- (void)hasConnected;
- (void)hasDisconnected;
- (void)playerDidWin;
- (void)playerDidLose;
- (void)playAudioWithResourceName:(NSString *)name;

@end

@interface MultipeerManager : NSObject

@property (nonatomic, weak) id<MultipeerClientDelegate>clientDelegate;
@property (nonatomic, weak) id<MultipeerServerDelegate>serverDelegate;

- (void)setupPeerAndSessionWithDisplayName:(NSString *)displayName;
- (MCBrowserViewController *)createMCBrowser;
- (void)advertiseSelf:(BOOL)shouldAdvertise;

- (void)broadcastString:(NSString *)string;
- (void)sendMessage:(NSString *)string toPeer:(NSString *)peerName;
- (void)sendResourcePath:(NSString *)path toPeer:(NSString *)peerName;

+ (instancetype)sharedInstance;

@end
