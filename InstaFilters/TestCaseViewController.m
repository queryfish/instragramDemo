//
//  TestCaseViewController.m
//  InstaFilters
//
//  Created by Steve on 14-3-3.
//  Copyright (c) 2014年 twitter:@diwup. All rights reserved.
//

#import "TestCaseViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface TestCaseViewController ()

@end

@implementation TestCaseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

-(void)viewWillAppear:(BOOL)animated
{
    NSUserDefaults* d = [NSUserDefaults standardUserDefaults];
    NSString* videopath = [d valueForKey:@"lastRecorded"];
    NSLog(@"there is a file %@", videopath);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)recordAVideo:(id)sender
{
    imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    imagePicker.mediaTypes = [NSArray arrayWithObject:@"public.movie"];
    imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
    
    imagePicker.allowsEditing = NO;
    imagePicker.showsCameraControls = YES;
    imagePicker.cameraViewTransform = CGAffineTransformIdentity;
    [imagePicker setDelegate:self];

    [self presentViewController:imagePicker animated:YES completion:nil];
}

-(void)filterIt:(id)sender
{
    
}

-(void)playIt:(id)sender
{
    NSString* rPath = [[NSBundle mainBundle] pathForResource:@"IMG_0701" ofType:@"MOV"];
    NSString* moviePath = [[NSUserDefaults standardUserDefaults]valueForKey:@"lastRecorded"];
    NSLog(@"last recorded path %@", rPath);
//    NSURL *movieURL = [NSURL fileURLWithPath:moviePath];
    NSURL *rUrl = [NSURL fileURLWithPath:rPath];
    MPMoviePlayerController*
    theMoviPlayer = [[MPMoviePlayerController alloc] initWithContentURL:rUrl];
    [theMoviPlayer setContentURL:rUrl];
    theMoviPlayer.controlStyle = MPMovieControlStyleNone;
    [theMoviPlayer prepareToPlay];
    [theMoviPlayer.view setBackgroundColor:[UIColor redColor]];
    [theMoviPlayer setMovieSourceType:MPMovieSourceTypeFile];
    [theMoviPlayer.view setFrame:self.imageView.frame];
    
    [self.view addSubview:theMoviPlayer.view];
    [theMoviPlayer play];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSURL *videoURL = [info valueForKey:UIImagePickerControllerMediaURL];
    NSString *tempPath = NSTemporaryDirectory();
    NSString *tempFile = [tempPath stringByAppendingPathComponent:@"lastRecorder"];

    NSData * data = [NSData dataWithContentsOfURL:videoURL];
    NSError* error = nil;
    [data writeToFile:tempFile options:NSDataWritingAtomic error:&error];
    if (error) {
        NSLog(@"save file failure %@", error);
    }
    else{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:tempFile forKey:@"lastRecorded"];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
    
}

@end
