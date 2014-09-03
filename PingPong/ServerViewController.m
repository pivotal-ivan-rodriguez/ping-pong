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

@interface ServerViewController () <MCBrowserViewControllerDelegate, MultipeerServerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *leftPlayerImageView;
@property (weak, nonatomic) IBOutlet UIImageView *rightPlayerImageView;
@property (weak, nonatomic) IBOutlet UILabel *leftServingLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightServingLabel;
@property (weak, nonatomic) IBOutlet UILabel *leftScoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightScoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *peersLabel;

@property (nonatomic) NSInteger leftScore;
@property (nonatomic) NSInteger rightScore;

@end

@implementation ServerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [MultipeerManager sharedInstance].serverDelegate = self;
    [[MultipeerManager sharedInstance] setupPeerAndSessionWithDisplayName:@"Server"];
    [[MultipeerManager sharedInstance] advertiseSelf:YES];
    [self showMultipeerBrowser];

    self.leftScore = 0;
    self.rightScore = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Helpers methods

- (void)showMultipeerBrowser {
    MCBrowserViewController *browserVC = [[MultipeerManager sharedInstance] createMCBrowser];
    browserVC.delegate = self;

    [self presentViewController:browserVC animated:YES completion:nil];
}

- (BOOL)leftPlayerWon {
    return (self.leftScore == 21);
}

- (BOOL)rightPlayerWon {
    return (self.rightScore == 21);
}

#pragma mark - UI updating helpers

- (void)scoreUpdated {
    [self informClientIfGameOver];
    [self updateScoreLabels];
    [self updateServingString];

}

- (void)informClientIfGameOver {
    NSString *winnerName;
    NSString *loserName;
    if ([self leftPlayerWon]) {
        winnerName = @"Left";
        loserName = @"Right";
    } else if ([self rightPlayerWon]) {
        winnerName = @"Right";
        loserName = @"Left";
    }
    if (winnerName) {
        [[MultipeerManager sharedInstance] sendMessage:@"win" toPeer:winnerName];
        [[MultipeerManager sharedInstance] sendMessage:@"lose" toPeer:loserName];
    }
}

- (void)updateScoreLabels {
    self.leftScoreLabel.text = [NSString stringWithFormat:@"%ld",(long)self.leftScore];
    self.rightScoreLabel.text = [NSString stringWithFormat:@"%ld",(long)self.rightScore];
}

- (void)updateServingString {
    BOOL scoreIsMultipleOfFive = ((self.rightScore + self.leftScore)%5==0);
    if (scoreIsMultipleOfFive) {
        self.leftServingLabel.hidden = !self.leftServingLabel.hidden;
        self.rightServingLabel.hidden = !self.rightServingLabel.hidden;
    }
}

- (void)resetGame {
    self.leftScore = 0;
    self.leftScoreLabel.text = @"0";
    self.rightScore = 0;
    self.rightScoreLabel.text = @"0";
}

#pragma mark - MultipeerManagerDelegate methods

- (void)connectedToPeerName:(NSString *)displayName {
    self.peersLabel.text = displayName;
}

- (void)disconnectedFromPeerName:(NSString *)displayName {
    self.peersLabel.text = @"--";
}

- (void)leftPlayerScored {
    self.leftScore ++;
    [self scoreUpdated];
}

- (void)rightPlayerScored {
    self.rightScore ++;
    [self scoreUpdated];
}

- (void)setupLeftImage:(UIImage *)image {

    UIImage * portraitImage = [[UIImage alloc] initWithCGImage: image.CGImage
                                                         scale: 1.0
                                                   orientation: UIImageOrientationRight];
    self.leftPlayerImageView.image = portraitImage;
}

- (void)setupRightImage:(UIImage *)image {
    UIImage * portraitImage = [[UIImage alloc] initWithCGImage: image.CGImage
                                                         scale: 1.0
                                                   orientation: UIImageOrientationRight];
    self.rightPlayerImageView.image = portraitImage;
}

#pragma mark - MCBrowserViewControllerDelegate Methods

-(void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}


-(void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - IBActions

- (IBAction)endGameTapped:(id)sender {
    [self resetGame];
}
- (IBAction)reconnectButtonTapped:(id)sender {
    [self showMultipeerBrowser];
}


@end
