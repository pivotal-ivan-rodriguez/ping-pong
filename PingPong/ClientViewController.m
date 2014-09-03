//
//  ClientViewController.m
//  PingPong
//
//  Created by DX169-XL on 2014-09-03.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "ClientViewController.h"
#import "MultipeerManager.h"

@import AVFoundation;

@interface ClientViewController () <MultipeerClientDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,AVAudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *gameSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *playerSegmentedControl;
@property (weak, nonatomic) IBOutlet UIImageView *profilePicture;
@property (weak, nonatomic) IBOutlet UILabel *addProfileImageLabel;
@property (weak, nonatomic) IBOutlet UILabel *connectionStateLabel;
@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation ClientViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [MultipeerManager sharedInstance].clientDelegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    //[self setupAsLeftPlayer];
}

#pragma mark - MultipeerManagerDelegate methods

- (void)hasConnected {
    //[self initialSetup];

    self.connectionStateLabel.text = @"Connected";
    self.connectionStateLabel.textColor = [UIColor greenColor];
}

- (void)hasDisconnected {
    self.connectionStateLabel.text = @"Disconnected";
    self.connectionStateLabel.textColor = [UIColor redColor];
}

- (void)playerDidWin {
    [[[UIAlertView alloc] initWithTitle:@"You win!" message:@"Yay!!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
}

- (void)playerDidLose {
    [[[UIAlertView alloc] initWithTitle:@"You lose!" message:@"Boo!!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
}

- (void)playAudioWithResourceName:(NSString *)name {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"m4a"];
    NSError *error;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&error];
    self.player = player;
    BOOL success = [player prepareToPlay];
    if (success) {
        [player play];
    }
}

#pragma mark - IBActions

- (IBAction)scoreButtonTapped:(UIButton *)sender {
    [[MultipeerManager sharedInstance] sendMessage:@"point" toPeer:@"Server"];
}


- (IBAction)addPhotoButtonTapped:(id)sender {
    UIImagePickerController *imagePickerController = [UIImagePickerController new];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;

    [self presentViewController:imagePickerController animated:NO completion:nil];
}

- (IBAction)resetGameButtonTapped:(UIBarButtonItem *)sender {
    [[MultipeerManager sharedInstance] sendMessage:@"reset" toPeer:@"Server"];
}

- (IBAction)gameSegmentedChanged:(UISegmentedControl *)sender {
    NSInteger pointsToWin = -1;
    if (sender.selectedSegmentIndex == 0) {
        pointsToWin = 11;
    } else if (sender.selectedSegmentIndex == 1) {
        pointsToWin = 21;
    }

    [self setupGameWithPointsToWin:@(pointsToWin)];
}

- (IBAction)playerSegmentedChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        [self setupAsLeftPlayer];
    } else if (sender.selectedSegmentIndex == 1) {
        [self setupAsRightPlayer];
    }
}

- (IBAction)minusOnePoint:(UIBarButtonItem *)sender {
    [[MultipeerManager sharedInstance] sendMessage:@"-1" toPeer:@"Server"];
}

#pragma mark - UIImagePickerControllerDelegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:NO completion:nil];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0), ^{

        UIImage *image = info[UIImagePickerControllerOriginalImage];

        NSString *savedImagePath = [self imagePath];
        NSData *imageData = UIImagePNGRepresentation(image);
        [imageData writeToFile:savedImagePath atomically:NO];

        [[MultipeerManager sharedInstance] sendResourcePath:savedImagePath toPeer:@"Server"];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.profilePicture.image = image;
            self.addProfileImageLabel.hidden = YES;
        });
    });
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private Methods

- (void)setupGameWithPointsToWin:(NSNumber *)pointsToWin {
    [[MultipeerManager sharedInstance] sendMessage:[pointsToWin stringValue] toPeer:@"Server"];
}

- (void)setupAsLeftPlayer {
    [[MultipeerManager sharedInstance] advertiseSelf:NO];

    [[MultipeerManager sharedInstance] setupPeerAndSessionWithDisplayName:@"Left"];
    [[MultipeerManager sharedInstance] advertiseSelf:YES];
}

- (void)setupAsRightPlayer {
    [[MultipeerManager sharedInstance] advertiseSelf:NO];

    [[MultipeerManager sharedInstance] setupPeerAndSessionWithDisplayName:@"Right"];
    [[MultipeerManager sharedInstance] advertiseSelf:YES];
}

- (void)initialSetup {
    [self setupGameWithPointsToWin:@(11)];
    [[MultipeerManager sharedInstance] sendResourcePath:[self imagePath] toPeer:@"Server"];
}

- (NSString *)imagePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *savedImagePath = [documentsDirectory stringByAppendingPathComponent:@"savedImage.png"];
    return savedImagePath;
}

@end
