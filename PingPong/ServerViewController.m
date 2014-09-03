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
@property (weak, nonatomic) IBOutlet UIProgressView *photoProgressView;
@property (weak, nonatomic) IBOutlet UILabel *leftPlayerConnectionStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightPlayerConnectionStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *serverConnectionStatusLabel;

@property (nonatomic) NSInteger leftScore;
@property (nonatomic) NSInteger rightScore;

@property (nonatomic) NSInteger pointsToWin;

@end

@implementation ServerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [MultipeerManager sharedInstance].serverDelegate = self;
    [[MultipeerManager sharedInstance] setupPeerAndSessionWithDisplayName:kServerKey];
    [[MultipeerManager sharedInstance] advertiseSelf:YES];
    [self showMultipeerBrowser];

    self.leftScore = 0;
    self.rightScore = 0;

    self.photoProgressView.hidden = YES;
}

#pragma mark - Helpers methods

- (void)showMultipeerBrowser {
    MCBrowserViewController *browserVC = [[MultipeerManager sharedInstance] createMCBrowser];
    browserVC.delegate = self;

    [self presentViewController:browserVC animated:YES completion:nil];
}

- (BOOL)leftPlayerWon {
    return (self.leftScore >= self.pointsToWin);
}

- (BOOL)rightPlayerWon {
    return (self.rightScore >= self.pointsToWin);
}

#pragma mark - UI updating helpers

- (void)scoreUpdated {
    [self updateScoreLabels];
    [self updateServingString];
    [self informClientIfGameOver];
    [self informClientOfServer];
}

- (void)informClientIfGameOver {
    NSString *winnerName;
    NSString *loserName;
    if ([self leftPlayerWon]) {
        winnerName = kLeftPlayerKey;
        loserName = kRightPlayerKey;

    } else if ([self rightPlayerWon]) {
        winnerName = kRightPlayerKey;
        loserName = kLeftPlayerKey;
    }
    if (winnerName) {
        [[MultipeerManager sharedInstance] sendMessage:kWinMessage toPeer:winnerName];
        [[MultipeerManager sharedInstance] sendMessage:kLoseMessage toPeer:loserName];
    }
}

- (void)informClientOfServer {
    BOOL isLeftPlayerServing = self.leftServingLabel.hidden == NO;

    NSString *playerName = isLeftPlayerServing ? kLeftPlayerKey : kRightPlayerKey;

    [[MultipeerManager sharedInstance] sendMessage:kYourServeMessage toPeer:playerName];
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

#pragma mark - MultipeerServerDelegate methods

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

- (void)clientTriggeredReset {
    [self resetGame];
}

- (void)setupGameWithPointsToWin:(NSInteger)pointsToWin {
    self.pointsToWin = pointsToWin;
}

- (void)minusOneToLeftScore {
    self.leftScore--;
    [self scoreUpdated];
}

- (void)minusOneToRightScore {
    self.rightScore--;
    [self scoreUpdated];
}

- (void)didStartDownloadingPhoto {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.photoProgressView.hidden = NO;
    });
}

- (void)photoDownloadPercent:(CGFloat)percent {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (percent > 0.99f) {
            self.photoProgressView.hidden = YES;
        }
        self.photoProgressView.progress = percent;
    });
}

- (void)leftPlayerConnected {
    self.leftPlayerConnectionStatusLabel.text = [NSString stringWithFormat:@"%@ Player Connected",kLeftPlayerKey];
    self.leftPlayerConnectionStatusLabel.textColor = [UIColor greenColor];
}

- (void)rightPlayerConnected {
    self.rightPlayerConnectionStatusLabel.text = [NSString stringWithFormat:@"%@ Player Connected",kRightPlayerKey];
    self.rightPlayerConnectionStatusLabel.textColor = [UIColor greenColor];
}

- (void)leftPlayerDisconnected {
    self.leftPlayerConnectionStatusLabel.text = [NSString stringWithFormat:@"%@ Player Disonnected",kLeftPlayerKey];
    self.leftPlayerConnectionStatusLabel.textColor = [UIColor redColor];
}

- (void)rightPlayerDisconnected {
    self.rightPlayerConnectionStatusLabel.text = [NSString stringWithFormat:@"%@ Player Disonnected",kRightPlayerKey];
    self.rightPlayerConnectionStatusLabel.textColor = [UIColor redColor];
}

- (void)serverConnected {
    self.serverConnectionStatusLabel.text = [NSString stringWithFormat:@"%@ Connected",kServerKey];
    self.serverConnectionStatusLabel.textColor = [UIColor greenColor];
}

- (void)serverDisconnected {
    self.serverConnectionStatusLabel.text = [NSString stringWithFormat:@"%@ Disonnected",kServerKey];
    self.serverConnectionStatusLabel.textColor = [UIColor redColor];
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
