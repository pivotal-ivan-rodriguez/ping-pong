//
//  MultipeerManager.h
//  PingPong
//
//  Created by DX169-XL on 2014-09-03.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MCBrowserViewController;

@interface MultipeerManager : NSObject

- (void)setupPeerAndSessionWithDisplayName:(NSString *)displayName;
- (MCBrowserViewController *)createMCBrowser;
- (void)advertiseSelf:(BOOL)shouldAdvertise;

+ (instancetype)sharedInstance;

@end
