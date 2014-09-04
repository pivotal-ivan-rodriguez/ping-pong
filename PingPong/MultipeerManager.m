//
//  MultipeerManager.m
//  PingPong
//
//  Created by DX169-XL on 2014-09-03.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "MultipeerManager.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface MultipeerManager () <MCSessionDelegate>

@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCAdvertiserAssistant *advertiser;
@property (nonatomic, strong) NSProgress *progress;
@end

@implementation MultipeerManager

#pragma mark - Public Methods

+ (instancetype)sharedInstance {
    static MultipeerManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)setupPeerAndSessionWithDisplayName:(NSString *)displayName{
    _peerID = [[MCPeerID alloc] initWithDisplayName:displayName];

    _session = [[MCSession alloc] initWithPeer:_peerID];
    _session.delegate = self;
}

- (MCBrowserViewController *)createMCBrowser {
    return [[MCBrowserViewController alloc] initWithServiceType:kServerServiceType session:_session];
}

-(void)advertiseSelf:(BOOL)shouldAdvertise{
    if (shouldAdvertise) {
        _advertiser = [[MCAdvertiserAssistant alloc] initWithServiceType:kServerServiceType
                                                           discoveryInfo:nil
                                                                 session:_session];
        [_advertiser start];
    }
    else{
        [_advertiser stop];
        _advertiser = nil;
    }
}

- (void)broadcastString:(NSString *)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    [self sendData:data toPeerIDs:self.session.connectedPeers];
}

- (void)sendMessage:(NSString *)string toPeer:(NSString *)peerName {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    MCPeerID  *peerID = [self getPeerFromPeerName:peerName];
    if (peerID) {
        [self sendData:data toPeerIDs:@[peerID]];
    }
}

- (void)sendResourcePath:(NSString *)path toPeer:(NSString *)peerName {
    [self.session sendResourceAtURL:[NSURL fileURLWithPath:path] withName:@"image" toPeer:[self getPeerFromPeerName:peerName] withCompletionHandler:^(NSError *error) {

    }];
}

#pragma mark - MCSessionDelegate Methods

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    if (state == MCSessionStateConnected) {
        if ([peerID.displayName isEqualToString:kLeftPlayerKey]) {
            [self.serverDelegate leftPlayerConnected];
            [self.clientDelegate hasConnected];
        } else if ([peerID.displayName isEqualToString:kRightPlayerKey]) {
            [self.serverDelegate rightPlayerConnected];
            [self.clientDelegate hasConnected];
        } else if ([peerID.displayName isEqualToString:kServerKey]) {
            [self.serverDelegate serverConnected];
        }
    } else if (state == MCSessionStateNotConnected) {
        if ([peerID.displayName isEqualToString:kLeftPlayerKey]) {
            [self.serverDelegate leftPlayerDisconnected];
            [self.clientDelegate hasDisconnected];
        } else if ([peerID.displayName isEqualToString:kRightPlayerKey]) {
            [self.serverDelegate rightPlayerDisconnected];
            [self.clientDelegate hasDisconnected];
        } else if ([peerID.displayName isEqualToString:kServerKey]) {
            [self.serverDelegate serverDisconnected];
        }
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([dataString isEqualToString:kPointMessage]) {
            if ([peerID.displayName isEqualToString:kLeftPlayerKey]) {
                [self.serverDelegate leftPlayerScored];
            } else if ([peerID.displayName isEqualToString:kRightPlayerKey]) {
                [self.serverDelegate rightPlayerScored];
            }
        } else if ([dataString isEqualToString:kResetMessage]) {
            [self.serverDelegate clientTriggeredReset];

        } else if ([dataString isEqualToString:kWinMessage]) {
            [self.clientDelegate playerDidWin];
        } else if ([dataString isEqualToString:kLoseMessage]) {
            [self.clientDelegate playerDidLose];
        } else if ([dataString isEqualToString:kElevenMessage]) {
            [self.serverDelegate setupGameWithPointsToWin:11];
        } else if ([dataString isEqualToString:kTwentyOneMessage]) {
            [self.serverDelegate setupGameWithPointsToWin:21];
        } else if ([dataString isEqualToString:kMinusOneMessage]) {
            if ([peerID.displayName isEqualToString:kLeftPlayerKey]) {
                [self.serverDelegate minusOneToLeftScore];
            } else if ([peerID.displayName isEqualToString:kRightPlayerKey]) {
                [self.serverDelegate minusOneToRightScore];
            }
        } else if ([dataString isEqualToString:kYourServeMessage]) {
            [self.clientDelegate playAudioWithResourceName:kYourServeMessage];
        } else if ([dataString isEqualToString:kChangeStartingServerMessage]) {
            [self.serverDelegate changeStartingServer];
        }
    });
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{
    self.progress = progress;
    [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionInitial context:NULL];

    [self.serverDelegate didStartDownloadingPhoto];
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error{

    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) context:NULL];
    self.progress = nil;

    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:localURL]];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([peerID.displayName isEqualToString:kLeftPlayerKey]) {
            [self.serverDelegate setupLeftImage:image];
        } else if ([peerID.displayName isEqualToString:kRightPlayerKey]) {
            [self.serverDelegate setupRightImage:image];
        }
    });
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID{
}

#pragma mark - Helper Methods

- (MCPeerID *)getPeerFromPeerName:(NSString *)peerName {
    for (MCPeerID *peerID in self.session.connectedPeers) {
        if ([peerID.displayName isEqualToString:peerName]) {
            return peerID;
        }
    }
    return nil;
}

- (void)sendData:(NSData *)data toPeerIDs:(NSArray *)peerIds {
    NSError *error = nil;
    [self.session sendData:data toPeers:peerIds withMode:MCSessionSendDataReliable error:&error];
    if (error) {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:error.description delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self.serverDelegate photoDownloadPercent:self.progress.fractionCompleted];
}

@end
