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
#import <MobileCoreServices/UTCoreTypes.h>
#import "GPUImageMovie.h"
#import "GPUImageView.h"
#import "GPUImagePicture.h"
#import "IFEarlybirdFilter.h"
#import "GPUImageMovieWriter.h"
#import "SXGPUImageMovie.h"
#import "IFRotationFilter.h"
#import "IFNormalFilter.h"
#import "FilterChooser.h"
#import "IFilterChooser.h"


@interface TestCaseViewController ()
{
    NSURL* mediaURL;
    GPUImageMovie* sourcer;
    GPUImagePicture* stillImage;
}

@property (nonatomic) MPMoviePlayerController *mp;
//@property (nonatomic) GPUImageView * afterFilter;

@property (nonatomic, strong) IFImageFilter *filter;

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
//    self.mp = [[MPMoviePlayerController alloc] init];
//    self.mp.controlStyle = MPMovieControlStyleNone;
//    [self.mp.view setBackgroundColor:[UIColor redColor]];
//    [self.mp.view setFrame:self.imageView.frame];
//    [self.view addSubview:self.mp.view];
//    _mp.controlStyle = MPMovieControlStyleNone;
//    mediaURL = [[NSBundle mainBundle]URLForResource:@"IMG_0701" withExtension:@"MOV"];
//    sourcer = [[GPUImageMovie alloc]initWithURL:mediaURL];
}

-(void)viewWillAppear:(BOOL)animated
{
    NSUserDefaults* d = [NSUserDefaults standardUserDefaults];
    NSString* videopath = [d valueForKey:@"lastRecorded"];
    NSLog(@"there is a file %@", videopath);
}

-(void)viewDidAppear:(BOOL)animated
{
//    NSURL* url = mediaURL?mediaURL:[[NSBundle mainBundle]URLForResource:@"IMG_0701" withExtension:@"MOV"];
//
//    dispatch_async(dispatch_get_main_queue(),
//    ^{
//        NSString* mediaPath = [url path];
//        [_mp setContentURL:url];
//        [_mp prepareToPlay];
//        NSLog(@"The media locate@%@, %f seconds",mediaPath, _mp.playableDuration);
//        _mp.initialPlaybackTime = 0;
//        [_mp play];
//    });
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

-(void)pickupAVideo:(id)sender
{
    imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    imagePicker.mediaTypes = @[(NSString*)kUTTypeImage, (NSString*)kUTTypeMovie];
    
    imagePicker.allowsEditing = NO;
    [imagePicker setDelegate:self];
    
    [self presentViewController:imagePicker animated:YES completion:nil];
}



-(void)chooseFilter:(id)sender
{
    FilterChooser* fc = [[FilterChooser alloc]initWithNibName:@"FilterChooser" bundle:nil];
    [fc setDoneHandler:^(IFImageFilter *f) {
        assert(f);
        self.filter = f;
    }];
    [self presentViewController:fc animated:YES completion:nil];
}

-(void)playImage:(id)sender
{
    NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:@"rocket" withExtension:@"png"];
    UIImage* imagesource = [UIImage imageWithContentsOfFile:[sampleURL path]];
    stillImage = [[GPUImagePicture alloc]initWithImage:imagesource];
    [stillImage addTarget:self.filter];
    CGRect frame = self.imageView.frame;
    frame.origin = CGPointZero;
    GPUImageView *filterView = [[GPUImageView alloc]initWithFrame:frame];
    [self.filter addTarget:filterView];
    [self.imageView addSubview:filterView];
    [stillImage processImage];
}

-(void)playFiltered:(id)sender
{
    //Just normal pipeline
    // GPUImageMovie|->GPUMovieWriter
    //              |->GPUImageView

    
    NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:@"mE" withExtension:@"mov"];
    
    SXGPUImageMovie* movieFile = [[SXGPUImageMovie alloc] initWithURL:sampleURL];

    [movieFile addTarget:self.filter];
//    IFRotationFilter* rotationFilter = [[IFRotationFilter alloc] initWithRotation:kGPUImageRotateRight];
//    [movieFile addTarget:rotationFilter];
//    [rotationFilter addTarget:self.filter];
    
    CGRect frame = self.imageView.frame;
    frame.origin = CGPointZero;
    GPUImageView *filterView = [[GPUImageView alloc]initWithFrame:frame];
    [self.imageView addSubview:filterView];
    [self.filter addTarget:filterView];

    
    // In addition to displaying to the screen, write out a processed version of the movie to disk
//    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mov"];
//    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
//    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
//    GPUImageMovieWriter* movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(640.0, 480.0)];
//    [filter addTarget:movieWriter];
//    
//    [movieWriter startRecording];
    [movieFile startProcessing];
    
}

-(void)playPlain:(id)sender
{
    NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:@"mE" withExtension:@"mov"];
    SXGPUImageMovie* movieFile = [[SXGPUImageMovie alloc] initWithURL:sampleURL];
    
    IFRotationFilter* rotationFilter = [[IFRotationFilter alloc] initWithRotation:kGPUImageRotateRight];
    [movieFile addTarget:rotationFilter];
    
    CGRect frame = self.imageView.frame;
    frame.origin = CGPointZero;
    GPUImageView *filterView = [[GPUImageView alloc]initWithFrame:frame];
    [self.imageView addSubview:filterView];
    
    [rotationFilter addTarget:filterView];
    [movieFile startProcessing];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    mediaURL = [info valueForKey:UIImagePickerControllerMediaURL];
//    NSString *tempPath = NSTemporaryDirectory();
//    NSString *tempFile = [tempPath stringByAppendingPathComponent:@"lastRecorder"];

//    NSData * data = [NSData dataWithContentsOfURL:videoURL];
//    NSError* error = nil;
//    [data writeToFile:tempFile options:NSDataWritingAtomic error:&error];
//    if (error) {
//        NSLog(@"save file failure %@", error);
//    }
//    else{
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//        [defaults setObject:tempFile forKey:@"lastRecorded"];
//    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
    
}

@end
