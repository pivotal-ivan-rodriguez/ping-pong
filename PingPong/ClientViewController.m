//
//  ClientViewController.m
//  PingPong
//
//  Created by DX169-XL on 2014-09-03.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "ClientViewController.h"
#import "MultipeerManager.h"

@interface ClientViewController () <MultipeerClientDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *leftPlayerButton;
@property (weak, nonatomic) IBOutlet UIButton *rightPlayerButton;
@property (weak, nonatomic) IBOutlet UIImageView *profilePicture;
@property (weak, nonatomic) IBOutlet UILabel *addProfileImageLabel;
@property (weak, nonatomic) IBOutlet UILabel *connectionStateLabel;

@end

@implementation ClientViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [MultipeerManager sharedInstance].clientDelegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

#pragma mark - MultipeerManagerDelegate methods

- (void)hasConnected {
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

#pragma mark - IBActions

- (IBAction)scoreButtonTapped:(UIButton *)sender {
    [[MultipeerManager sharedInstance] sendMessage:@"point" toPeer:@"Server"];
}

- (IBAction)setupAsLeftPlayer:(id)sender {
    [[MultipeerManager sharedInstance] setupPeerAndSessionWithDisplayName:@"Left"];
    [[MultipeerManager sharedInstance] advertiseSelf:YES];
    self.rightPlayerButton.hidden = YES;
}

- (IBAction)setupAsRightPlayer:(id)sender {
    [[MultipeerManager sharedInstance] setupPeerAndSessionWithDisplayName:@"Right"];
    [[MultipeerManager sharedInstance] advertiseSelf:YES];
    self.leftPlayerButton.hidden = YES;
}

- (IBAction)addPhotoButtonTapped:(id)sender {
    UIImagePickerController *imagePickerController = [UIImagePickerController new];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;

    [self presentViewController:imagePickerController animated:NO completion:nil];
}

- (IBAction)resetGameButtonTapped:(UIButton *)sender {
}

#pragma mark - UIImagePickerControllerDelegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:NO completion:nil];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0), ^{

        UIImage *image = info[UIImagePickerControllerOriginalImage];

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *savedImagePath = [documentsDirectory stringByAppendingPathComponent:@"savedImage.png"];
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

@end
