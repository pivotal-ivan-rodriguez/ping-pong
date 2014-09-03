//
//  ViewController.m
//  PingPong
//
//  Created by DX169-XL on 2014-09-03.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "ServerViewController.h"
#import "MultipeerManager.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface ServerViewController () <MCBrowserViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *leftPlayerImageView;
@property (weak, nonatomic) IBOutlet UIImageView *rightPlayerImageView;

@property (weak, nonatomic) IBOutlet UILabel *leftServingLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightServingLabel;

@property (weak, nonatomic) IBOutlet UILabel *leftScoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightScoreLabel;

@end

@implementation ServerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[MultipeerManager sharedInstance] setupPeerAndSessionWithDisplayName:@"Server"];
    [[MultipeerManager sharedInstance] advertiseSelf:YES];
    MCBrowserViewController *browserVC = [[MultipeerManager sharedInstance] createMCBrowser];
    browserVC.delegate = self;

    [self presentViewController:browserVC animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - MCBrowserViewControllerDelegate Methods

-(void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}


-(void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
