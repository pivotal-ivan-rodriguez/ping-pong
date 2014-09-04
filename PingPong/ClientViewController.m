//
//  ClientViewController.m
//  PingPong
//
//  Created by DX169-XL on 2014-09-03.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "ClientViewController.h"
#import "MultipeerManager.h"
#import "ConfettiScreen.h"

@import AVFoundation;

@interface ClientViewController () <MultipeerClientDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,AVAudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *gameSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *playerSegmentedControl;
@property (weak, nonatomic) IBOutlet UIImageView *profilePicture;
@property (weak, nonatomic) IBOutlet UILabel *addProfileImageLabel;
@property (weak, nonatomic) IBOutlet UILabel *connectionStateLabel;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, weak) ConfettiScreen *confettiScreen;
@property (weak, nonatomic) IBOutlet UIView *confettiView;

@end

@implementation ClientViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [MultipeerManager sharedInstance].clientDelegate = self;
    [self setupAsLeftPlayer];
}

#pragma mark - MultipeerManagerDelegate methods

- (void)hasConnected {
    [self initialSetup];

    self.connectionStateLabel.text = @"Connected";
}

- (void)hasDisconnected {
    self.connectionStateLabel.text = @"Disconnected";
}

- (void)playerDidWin {
    [self startConfettiAnimationInRect:self.view.bounds win:YES];
    [self playAudioForAudioName:@"win"];
}

- (void)playerDidLose {
    [self startConfettiAnimationInRect:self.view.bounds win:NO];
    [self playAudioForAudioName:@"lose"];
}

- (void)playAudioForAudioName:(NSString *)audioName {
    NSString *path = [[NSBundle mainBundle] pathForResource:audioName ofType:@"mp3"];
    NSError *error;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&error];
    self.player = player;
    BOOL success = [player prepareToPlay];
    if (success) {
        [player play];
    }
}

- (void)setupGameWithPointsToWin:(NSInteger)pointsToWin {
    if (pointsToWin == 11) {
        self.gameSegmentedControl.selectedSegmentIndex = 0;
    } else {
        self.gameSegmentedControl.selectedSegmentIndex = 1;
    }
}

- (void)triggeredReset {
    [self resetGame];
}

#pragma mark - IBActions

- (IBAction)scoreButtonTapped:(UIButton *)sender {
    [[MultipeerManager sharedInstance] sendMessage:kPointMessage toPeer:kServerKey];
}

- (IBAction)addPhotoButtonTapped:(id)sender {
    UIImagePickerController *imagePickerController = [UIImagePickerController new];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;

    [self presentViewController:imagePickerController animated:NO completion:nil];
}

- (IBAction)resetGameButtonTapped:(UIBarButtonItem *)sender {
    [self resetGame];
    [[MultipeerManager sharedInstance] sendMessage:kResetMessage toPeer:kServerKey];
}

- (IBAction)gameSegmentedChanged:(UISegmentedControl *)sender {
    NSInteger pointsToWin = [self pointsToWinFromSelection:sender.selectedSegmentIndex];

    [self changeGameWithPointsToWin:@(pointsToWin)];
}

- (IBAction)playerSegmentedChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        [self setupAsLeftPlayer];
    } else if (sender.selectedSegmentIndex == 1) {
        [self setupAsRightPlayer];
    }
}

- (IBAction)opponentScoredButtonTapped:(id)sender {
    [[MultipeerManager sharedInstance] sendMessage:kOpponentPointMessage toPeer:kServerKey];
}

- (IBAction)minusOnePoint:(UIBarButtonItem *)sender {
    [[MultipeerManager sharedInstance] sendMessage:kMinusOneMessage toPeer:kServerKey];
}

- (IBAction)changeStartingServerTapped:(id)sender {
    [[MultipeerManager sharedInstance] sendMessage:kChangeStartingServerMessage toPeer:kServerKey];
}

#pragma mark - UIImagePickerControllerDelegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:NO completion:nil];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0), ^{

        UIImage *image = info[UIImagePickerControllerOriginalImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.profilePicture.image = image;
            self.addProfileImageLabel.hidden = YES;
        });

        NSString *savedImagePath = [self imagePath];
        NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
        [imageData writeToFile:savedImagePath atomically:NO];

        [[MultipeerManager sharedInstance] sendResourcePath:savedImagePath toPeer:kServerKey];
    });
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private Methods

- (void)changeGameWithPointsToWin:(NSNumber *)pointsToWin {
    [[MultipeerManager sharedInstance] sendMessage:[pointsToWin stringValue] toPeer:kServerKey];
}

- (void)setupAsLeftPlayer {
    [[MultipeerManager sharedInstance] advertiseSelf:NO];

    [[MultipeerManager sharedInstance] setupPeerAndSessionWithDisplayName:kLeftPlayerKey];
    [[MultipeerManager sharedInstance] advertiseSelf:YES];

    self.view.backgroundColor = [UIColor colorWithRed:1 green:103/255.0f blue:105/255.0f alpha:1];
}

- (void)setupAsRightPlayer {
    [[MultipeerManager sharedInstance] advertiseSelf:NO];

    [[MultipeerManager sharedInstance] setupPeerAndSessionWithDisplayName:kRightPlayerKey];
    [[MultipeerManager sharedInstance] advertiseSelf:YES];
    
    self.view.backgroundColor = [UIColor colorWithRed:108/255.0f green:90/255.0f blue:1 alpha:1];
}

- (void)initialSetup {
    [self changeGameWithPointsToWin:@([self pointsToWinFromSelection:self.gameSegmentedControl.selectedSegmentIndex])];
}

- (NSString *)imagePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *savedImagePath = [documentsDirectory stringByAppendingPathComponent:@"savedImage.png"];
    return savedImagePath;
}

- (NSInteger)pointsToWinFromSelection:(NSInteger)index{
    NSInteger pointsToWin = -1;
    if (index == 0) {
        pointsToWin = 11;
    } else if (index == 1) {
        pointsToWin = 21;
    }
    return pointsToWin;
}

- (void)startConfettiAnimationInRect:(CGRect)rect win:(BOOL)win {
    ConfettiScreen *confetti = [[ConfettiScreen alloc] initWithFrame:rect win:win];
    self.confettiScreen = confetti;
    [self.confettiView addSubview:confetti];
}

- (void)stopConfettiAnimation {
    [self.confettiScreen stopEmitting];
    for (UIView *view in self.confettiView.subviews) {
        [view removeFromSuperview];
    }
}

- (void)resetGame {
    [self stopConfettiAnimation];
}

@end
