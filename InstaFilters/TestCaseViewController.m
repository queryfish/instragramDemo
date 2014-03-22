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
#import "GPUImageRawData.h"

@interface TestCaseViewController ()<UIAlertViewDelegate>
{
    NSURL* mediaURL;
    GPUImageMovie* sourcer;
    GPUImagePicture* stillImage;
    UIImageView * frameView;
    NSInteger currentFilterType;
}

@property (nonatomic, strong) IFImageFilter *filter;
@property (nonatomic, strong) GPUImagePicture *stillImageSource;
@property (nonatomic, strong) GPUImagePicture *sourcePicture1;
@property (nonatomic, strong) GPUImagePicture *sourcePicture2;
@property (nonatomic, strong) GPUImagePicture *sourcePicture3;
@property (nonatomic, strong) GPUImagePicture *sourcePicture4;
@property (nonatomic, strong) GPUImagePicture *sourcePicture5;

@property (nonatomic, strong) IFImageFilter *internalFilter;
@property (nonatomic, strong) GPUImagePicture *internalSourcePicture1;
@property (nonatomic, strong) GPUImagePicture *internalSourcePicture2;
@property (nonatomic, strong) GPUImagePicture *internalSourcePicture3;
@property (nonatomic, strong) GPUImagePicture *internalSourcePicture4;
@property (nonatomic, strong) GPUImagePicture *internalSourcePicture5;
@property (nonatomic, strong) IFRotationFilter* rotationFilter;

@property (nonatomic, strong) UIImage* rawImage;
@property (nonatomic, strong) GPUImageView* gpuImageView;

@property (nonatomic, assign) NSInteger filterIndex;
@property (nonatomic, strong) SXGPUImageMovie* movieSource;
@property (nonatomic, strong) GPUImageMovieWriter* movieWriter;

//@property (nonatomic, strong) MPMoviePlayerViewController* mplayer;

@property (nonatomic, strong) MPMoviePlayerController* mplayer;

@property (nonatomic, strong)     UIActivityIndicatorView* waiter ;

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

    [self.recorderButton.layer setCornerRadius:50];
    [self.filterButton.layer setCornerRadius:50];
    [self.playButton.layer setCornerRadius:35];
    [self.saveButton.layer setCornerRadius:35];
    
    CGRect frame = self.imageView.frame;
    frame.origin = CGPointZero;

    NSURL* t = [self fileURLForTempMovie];
    [self removeFile:t];

    self.gpuImageView = [[GPUImageView alloc]initWithFrame:frame];
    self.movieWriter = [[GPUImageMovieWriter alloc]initWithMovieURL:t size:(CGSize){480, 480}];
    self.rotationFilter = [[IFRotationFilter alloc]initWithRotation:kGPUImageRotateRight];
    self.filter = [IFNormalFilter new];
    [self.rotationFilter addTarget:self.filter];
    
    [self.imageView addSubview:self.gpuImageView];
    self.waiter = [[UIActivityIndicatorView alloc]initWithFrame:self.imageView.frame];
    [self.waiter setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.waiter setColor:[UIColor blueColor]];
    [self.view addSubview:self.waiter];

}

-(NSURL *)fileURLForFirstPassRec
{
    static NSURL *tempMoviewURL = nil;
    @synchronized(self) {
        if (tempMoviewURL == nil) {
            tempMoviewURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"firstpass.m4v"]];
        }
    }
    
    return tempMoviewURL;
}


- (NSURL *)fileURLForTempMovie
{
    static NSURL *tempMoviewURL = nil;
    
    @synchronized(self) {
        if (tempMoviewURL == nil) {
            tempMoviewURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"temp.m4v"]];
        }
    }
    
    return tempMoviewURL;
}

- (NSURL *)fileURLForFinalMixedAsset
{
    static NSURL *tempMixedAssetURL = nil;
    
    @synchronized(self) {
        if (tempMixedAssetURL == nil) {
            tempMixedAssetURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"tempMix.m4v"]];
        }
    }
    
    return tempMixedAssetURL;
}

- (void)removeFile:(NSURL *)fileURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [fileURL path];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
		if (!success) {
            NSLog(@" - Remove file failed...");
        }
    }
}


- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    
}

- (void)combineSoundAndMovie:(void(^)(NSError*))handle
{
//    self.mutableComposition = [AVMutableComposition composition];
    AVMutableComposition* mutableComposition = [AVMutableComposition composition];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], AVURLAssetPreferPreciseDurationAndTimingKey, nil];
    
    NSURL * target = [self fileURLForTempMovie];
    AVURLAsset *movieURLAsset = [[AVURLAsset alloc] initWithURL:target
                                                        options:options];
    
    AVURLAsset *soundURLAsset = [[AVURLAsset alloc] initWithURL:[self fileURLForFirstPassRec]
                                                        options:options];
    
    NSError *soundError = nil;
    AVMutableCompositionTrack *soundTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    BOOL soundResult = [soundTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, soundURLAsset.duration)
                                           ofTrack:[[soundURLAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                            atTime:kCMTimeZero
                                             error:&soundError];
    
    if (soundError != nil) {
        NSLog(@" - sound track error...");
    }
    
    if (soundResult == NO) {
        NSLog(@" - sound result = NO...");
    }

    NSError *movieError = nil;
    AVMutableCompositionTrack *movieTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    BOOL movieResult = [movieTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, movieURLAsset.duration) ofTrack:[[movieURLAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:&movieError];
    
    if (movieError != nil) {
        NSLog(@" - movie track error...");
    }
    
    if (movieResult == NO) {
        NSLog(@" - movie result = NO...");
    }
    
    AVAssetExportSession* assetExportSession = [[AVAssetExportSession alloc] initWithAsset:mutableComposition presetName:AVAssetExportPresetPassthrough];
    
    [self removeFile:[self fileURLForFinalMixedAsset]];
    
    assetExportSession.outputURL = [self fileURLForFinalMixedAsset];
    assetExportSession.outputFileType = AVFileTypeAppleM4V;
    __weak typeof(self) _weakself = self;
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        
        switch (assetExportSession.status) {
            case AVAssetExportSessionStatusFailed: {
                NSString* error = [NSString stringWithFormat:@"Export failed, %@", assetExportSession.error];
                NSLog(@"%@",error);
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                                    message:error
                                                                   delegate:nil
                                                          cancelButtonTitle:@"Oh ok"
                                                          otherButtonTitles:nil];
                [alertView show];
                break;
            }
            case AVAssetExportSessionStatusCompleted: {
                NSLog(@" - Export ok...");
                handle?handle(nil):0;
                break;
            }
            default: {
                break;
            }
        };
        
    }];
    
}

-(void)play:(id)sender
{
    NSURL* t = [self fileURLForFinalMixedAsset];
    if(!self.mplayer)
        self.mplayer = [[MPMoviePlayerController alloc]initWithContentURL:t];
    else
        [self.mplayer setContentURL:t];
    
    [self.mplayer.view setHidden:NO];
    [self.mplayer setControlStyle:MPMovieControlStyleNone];
    [self.mplayer.view setFrame:self.imageView.frame];
    [self.view addSubview:self.mplayer.view];
    [self.mplayer play];

}



-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1){
    NSString* path = [[self fileURLForFinalMixedAsset] path];
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (path))
    {
        UISaveVideoAtPathToSavedPhotosAlbum (path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
    }
}

-(void)save:(id)sender
{
//    [self combineSoundAndMovie:^(NSError* erro){
//        dispatch_async(dispatch_get_main_queue(), ^{
    
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops" message:@"Save it to your album?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"YES",nil];
            [alertView show];
//        });
//    }];

}

#pragma Pipeline Utilities

-(void)record:(id)sender
{
    [self.mplayer.view clearsContextBeforeDrawing];
    
    [self removeFile:[self fileURLForTempMovie]];
     imagePicker = [[UIImagePickerController alloc] init];
     imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
     imagePicker.mediaTypes = @[(NSString*)kUTTypeMovie];
     imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
     imagePicker.allowsEditing = NO;
     imagePicker.showsCameraControls = YES;
     imagePicker.cameraViewTransform = CGAffineTransformIdentity;
     [imagePicker setDelegate:self];
    
     [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    mediaURL = [info valueForKey:UIImagePickerControllerMediaURL];
    NSURL* firstPass = [self fileURLForFirstPassRec];
    [self removeFile:firstPass];
    NSData * data = [NSData dataWithContentsOfURL:mediaURL];
    BOOL good = [data writeToURL:firstPass atomically:YES];
    if (!good) {
        NSLog(@"save file failure ");
    }
    dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:YES completion:nil];
            });
}


-(void)filter:(id)sender
{
    FilterChooser* fc = [[FilterChooser alloc]initWithNibName:@"FilterChooser" bundle:nil];
    __weak typeof(self) _weakself = self;
    [fc setDoneHandler:^(NSString* filterName, NSInteger index) {
        [_weakself.filterName setText:filterName];
        _weakself.filterIndex = index;
        [_weakself reloadFilters:index];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_weakself startFiltering];
        });
    }];
    [self presentViewController:fc animated:YES completion:nil];
}

-(void)startFiltering
{
    [self removeFile:[self fileURLForTempMovie]];
    NSURL* sampleURL = [self fileURLForFirstPassRec];
    __weak typeof(self) _weakself = self;
    self.movieSource = [[SXGPUImageMovie alloc] initWithURL:sampleURL];
    self.movieWriter = [[GPUImageMovieWriter alloc]initWithMovieURL:[self fileURLForTempMovie] size:(CGSize){640,480}];
    [self.waiter setHidesWhenStopped:YES];
    [self.waiter  startAnimating];
    [self.movieSource setDoneHandler:^{
        [_weakself.movieWriter finishRecording];
        [_weakself combineSoundAndMovie:^(NSError *e) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[_weakself waiter] stopAnimating];
            });
        }];
    }];
    [self.mplayer.view setHidden:YES];
    //#! Make sure the internal filters are setup before this stage.
    [self.movieSource addTarget:self.rotationFilter];
    [self.filter addTarget:self.movieWriter];
    [self.filter addTarget:self.gpuImageView];
    [self.movieSource startProcessing];
    [self.movieWriter startRecording];
    
}


#pragma mark - Switch Filter
- (void)rebuildPipleline
{
    //#!KEEP THE SEQUENCE IS CRITICAL FOR PIPELINE
    [self.rotationFilter removeAllTargets];
    self.filter = self.internalFilter;
    [self.rotationFilter addTarget:self.filter];

    switch (currentFilterType) {
        case IF_AMARO_FILTER: {
            self.sourcePicture1 = self.internalSourcePicture1;
            self.sourcePicture2 = self.internalSourcePicture2;
            self.sourcePicture3 = self.internalSourcePicture3;
            
            [self.sourcePicture1 addTarget:self.filter];
            [self.sourcePicture2 addTarget:self.filter];
            [self.sourcePicture3 addTarget:self.filter];
            
            break;
        }
            
        case IF_RISE_FILTER: {
            self.sourcePicture1 = self.internalSourcePicture1;
            self.sourcePicture2 = self.internalSourcePicture2;
            self.sourcePicture3 = self.internalSourcePicture3;
            
            [self.sourcePicture1 addTarget:self.filter];
            [self.sourcePicture2 addTarget:self.filter];
            [self.sourcePicture3 addTarget:self.filter];
            
            break;
        }
            
        case IF_HUDSON_FILTER: {
            self.sourcePicture1 = self.internalSourcePicture1;
            self.sourcePicture2 = self.internalSourcePicture2;
            self.sourcePicture3 = self.internalSourcePicture3;
            
            [self.sourcePicture1 addTarget:self.filter];
            [self.sourcePicture2 addTarget:self.filter];
            [self.sourcePicture3 addTarget:self.filter];
            
            break;
        }
            
        case IF_XPROII_FILTER: {
            self.sourcePicture1 = self.internalSourcePicture1;
            self.sourcePicture2 = self.internalSourcePicture2;
            
            [self.sourcePicture1 addTarget:self.filter];
            [self.sourcePicture2 addTarget:self.filter];
            
            break;
        }
            
        case IF_SIERRA_FILTER: {
            self.sourcePicture1 = self.internalSourcePicture1;
            self.sourcePicture2 = self.internalSourcePicture2;
            self.sourcePicture3 = self.internalSourcePicture3;
            
            [self.sourcePicture1 addTarget:self.filter];
            [self.sourcePicture2 addTarget:self.filter];
            [self.sourcePicture3 addTarget:self.filter];
            
            break;
        }
            
        case IF_LOMOFI_FILTER: {
            self.sourcePicture1 = self.internalSourcePicture1;
            self.sourcePicture2 = self.internalSourcePicture2;
            
            [self.sourcePicture1 addTarget:self.filter];
            [self.sourcePicture2 addTarget:self.filter];
            
            break;
        }
            
        case IF_EARLYBIRD_FILTER: {
            self.sourcePicture1 = self.internalSourcePicture1;
            self.sourcePicture2 = self.internalSourcePicture2;
            self.sourcePicture3 = self.internalSourcePicture3;
            self.sourcePicture4 = self.internalSourcePicture4;
            self.sourcePicture5 = self.internalSourcePicture5;
            
            [self.sourcePicture1 addTarget:self.filter];
            [self.sourcePicture2 addTarget:self.filter];
            [self.sourcePicture3 addTarget:self.filter];
            [self.sourcePicture4 addTarget:self.filter];
            [self.sourcePicture5 addTarget:self.filter];
            
            break;
        }
            
        case IF_SUTRO_FILTER: {
            self.sourcePicture1 = self.internalSourcePicture1;
            self.sourcePicture2 = self.internalSourcePicture2;
            self.sourcePicture3 = self.internalSourcePicture3;
            self.sourcePicture4 = self.internalSourcePicture4;
            self.sourcePicture5 = self.internalSourcePicture5;
            
            [self.sourcePicture1 addTarget:self.filter];
            [self.sourcePicture2 addTarget:self.filter];
            [self.sourcePicture3 addTarget:self.filter];
            [self.sourcePicture4 addTarget:self.filter];
            [self.sourcePicture5 addTarget:self.filter];
            
            break;
        }
            
        case IF_TOASTER_FILTER: {
            self.sourcePicture1 = self.internalSourcePicture1;
            self.sourcePicture2 = self.internalSourcePicture2;
            self.sourcePicture3 = self.internalSourcePicture3;
            self.sourcePicture4 = self.internalSourcePicture4;
            self.sourcePicture5 = self.internalSourcePicture5;
            
            [self.sourcePicture1 addTarget:self.filter];
            [self.sourcePicture2 addTarget:self.filter];
            [self.sourcePicture3 addTarget:self.filter];
            [self.sourcePicture4 addTarget:self.filter];
            [self.sourcePicture5 addTarget:self.filter];
            
            break;
        }
            
        case IF_BRANNAN_FILTER: {
            self.sourcePicture1 = self.internalSourcePicture1;
            self.sourcePicture2 = self.internalSourcePicture2;
            self.sourcePicture3 = self.internalSourcePicture3;
            self.sourcePicture4 = self.internalSourcePicture4;
            self.sourcePicture5 = self.internalSourcePicture5;
            
            [self.sourcePicture1 addTarget:self.filter];
            [self.sourcePicture2 addTarget:self.filter];
            [self.sourcePicture3 addTarget:self.filter];
            [self.sourcePicture4 addTarget:self.filter];
            [self.sourcePicture5 addTarget:self.filter];
            
            break;
        }
            
        case IF_INKWELL_FILTER: {
            
            self.sourcePicture1 = self.internalSourcePicture1;
            
            [self.sourcePicture1 addTarget:self.filter];
            
            break;
        }
            
        case IF_WALDEN_FILTER: {
            self.sourcePicture1 = self.internalSourcePicture1;
            self.sourcePicture2 = self.internalSourcePicture2;
            
            [self.sourcePicture1 addTarget:self.filter];
            [self.sourcePicture2 addTarget:self.filter];
            
            break;
        }
            
        case IF_HEFE_FILTER: {
            self.sourcePicture1 = self.internalSourcePicture1;
            self.sourcePicture2 = self.internalSourcePicture2;
            self.sourcePicture3 = self.internalSourcePicture3;
            self.sourcePicture4 = self.internalSourcePicture4;
            self.sourcePicture5 = self.internalSourcePicture5;
            
            [self.sourcePicture1 addTarget:self.filter];
            [self.sourcePicture2 addTarget:self.filter];
            [self.sourcePicture3 addTarget:self.filter];
            [self.sourcePicture4 addTarget:self.filter];
            [self.sourcePicture5 addTarget:self.filter];
            
            break;
        }
            
        case IF_VALENCIA_FILTER: {
            self.sourcePicture1 = self.internalSourcePicture1;
            self.sourcePicture2 = self.internalSourcePicture2;
            
            [self.sourcePicture1 addTarget:self.filter];
            [self.sourcePicture2 addTarget:self.filter];
            
            break;
        }
            
        case IF_NASHVILLE_FILTER: {
            self.sourcePicture1 = self.internalSourcePicture1;
            
            [self.sourcePicture1 addTarget:self.filter];
            
            break;
        }
            
        case IF_1977_FILTER: {
            self.sourcePicture1 = self.internalSourcePicture1;
            self.sourcePicture2 = self.internalSourcePicture2;
            
            [self.sourcePicture1 addTarget:self.filter];
            [self.sourcePicture2 addTarget:self.filter];
            
            break;
        }
            
        case IF_LORDKELVIN_FILTER: {
            self.sourcePicture1 = self.internalSourcePicture1;
            
            [self.sourcePicture1 addTarget:self.filter];
            
            break;
        }
            
        case IF_NORMAL_FILTER: {
            break;
        }
            
        default: {
            break;
        }
    }
}

-(void)reloadFilters:(IFFilterType)type
{
    if (currentFilterType == type)
        return;
    [self forceSwitchToNewFilter:type];

}

//- (void)switchFilter:(IFFilterType)type {
//    
//    if ((self.rawImage != nil) && (self.stillImageSource == nil))
//    {
//        // This is the state when we just switched from live view to album photo view
//        self.stillImageSource = [[GPUImagePicture alloc] initWithImage:self.rawImage];
//        [self.stillImageSource addTarget:self.filter];
//    }
//    else if(self.movieSource != nil)
//    {
//        
//        if (currentFilterType == type) {
//            return;
//        }
//    }
//    
//    [self forceSwitchToNewFilter:type];
//}

- (void)forceSwitchToNewFilter:(IFFilterType)type {
    
    currentFilterType = type;
    
    switch (type) {
        case IF_AMARO_FILTER: {
            self.internalFilter = [[IFAmaroFilter alloc] init];
            self.internalSourcePicture1 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"blackboard1024" ofType:@"png"]]];
            self.internalSourcePicture2 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"overlayMap" ofType:@"png"]]];
            self.internalSourcePicture3 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"amaroMap" ofType:@"png"]]];
            break;
        }
            
        case IF_NORMAL_FILTER: {
            self.internalFilter = [[IFNormalFilter alloc] init];
            break;
        }
            
        case IF_RISE_FILTER: {
            self.internalFilter = [[IFRiseFilter alloc] init];
            self.internalSourcePicture1 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"blackboard1024" ofType:@"png"]]];
            self.internalSourcePicture2 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"overlayMap" ofType:@"png"]]];
            self.internalSourcePicture3 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"riseMap" ofType:@"png"]]];
            
            break;
        }
            
        case IF_HUDSON_FILTER: {
            self.internalFilter = [[IFHudsonFilter alloc] init];
            self.internalSourcePicture1 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"hudsonBackground" ofType:@"png"]]];
            self.internalSourcePicture2 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"overlayMap" ofType:@"png"]]];
            self.internalSourcePicture3 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"hudsonMap" ofType:@"png"]]];
            
            break;
        }
            
        case IF_XPROII_FILTER: {
            self.internalFilter = [[IFXproIIFilter alloc] init];
            self.internalSourcePicture1 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"vignetteMap" ofType:@"png"]]];
            self.internalSourcePicture2 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"xproMap" ofType:@"png"]]];
            
            break;
        }
            
        case IF_SIERRA_FILTER: {
            self.internalFilter = [[IFSierraFilter alloc] init];
            self.internalSourcePicture1 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sierraVignette" ofType:@"png"]]];
            self.internalSourcePicture2 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"overlayMap" ofType:@"png"]]];
            self.internalSourcePicture3 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sierraMap" ofType:@"png"]]];
            
            
            break;
        }
            
        case IF_LOMOFI_FILTER: {
            self.internalFilter = [[IFLomofiFilter alloc] init];
            self.internalSourcePicture1 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"lomoMap" ofType:@"png"]]];
            self.internalSourcePicture2 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"vignetteMap" ofType:@"png"]]];
            
            break;
        }
            
        case IF_EARLYBIRD_FILTER: {
            self.internalFilter = [[IFEarlybirdFilter alloc] init];
            self.internalSourcePicture1 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"earlyBirdCurves" ofType:@"png"]]];
            self.internalSourcePicture2 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"earlybirdOverlayMap" ofType:@"png"]]];
            self.internalSourcePicture3 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"vignetteMap" ofType:@"png"]]];
            self.internalSourcePicture4 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"earlybirdBlowout" ofType:@"png"]]];
            self.internalSourcePicture5 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"earlybirdMap" ofType:@"png"]]];
            
            
            break;
        }
            
        case IF_SUTRO_FILTER: {
            self.internalFilter = [[IFSutroFilter alloc] init];
            self.internalSourcePicture1 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"vignetteMap" ofType:@"png"]]];
            self.internalSourcePicture2 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sutroMetal" ofType:@"png"]]];
            self.internalSourcePicture3 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"softLight" ofType:@"png"]]];
            self.internalSourcePicture4 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sutroEdgeBurn" ofType:@"png"]]];
            self.internalSourcePicture5 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sutroCurves" ofType:@"png"]]];
            
            
            break;
        }
            
        case IF_TOASTER_FILTER: {
            self.internalFilter = [[IFToasterFilter alloc] init];
            self.internalSourcePicture1 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"toasterMetal" ofType:@"png"]]];
            self.internalSourcePicture2 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"toasterSoftLight" ofType:@"png"]]];
            self.internalSourcePicture3 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"toasterCurves" ofType:@"png"]]];
            self.internalSourcePicture4 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"toasterOverlayMapWarm" ofType:@"png"]]];
            self.internalSourcePicture5 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"toasterColorShift" ofType:@"png"]]];
            
            
            break;
        }
            
        case IF_BRANNAN_FILTER: {
            self.internalFilter = [[IFBrannanFilter alloc] init];
            self.internalSourcePicture1 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"brannanProcess" ofType:@"png"]]];
            self.internalSourcePicture2 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"brannanBlowout" ofType:@"png"]]];
            self.internalSourcePicture3 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"brannanContrast" ofType:@"png"]]];
            self.internalSourcePicture4 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"brannanLuma" ofType:@"png"]]];
            self.internalSourcePicture5 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"brannanScreen" ofType:@"png"]]];
            
            
            break;
        }
            
        case IF_INKWELL_FILTER: {
            self.internalFilter = [[IFInkwellFilter alloc] init];
            self.internalSourcePicture1 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"inkwellMap" ofType:@"png"]]];
            
            break;
        }
            
        case IF_WALDEN_FILTER: {
            self.internalFilter = [[IFWaldenFilter alloc] init];
            self.internalSourcePicture1 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"waldenMap" ofType:@"png"]]];
            self.internalSourcePicture2 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"vignetteMap" ofType:@"png"]]];
            
            break;
        }
            
        case IF_HEFE_FILTER: {
            self.internalFilter = [[IFHefeFilter alloc] init];
            self.internalSourcePicture1 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"edgeBurn" ofType:@"png"]]];
            self.internalSourcePicture2 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"hefeMap" ofType:@"png"]]];
            self.internalSourcePicture3 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"hefeGradientMap" ofType:@"png"]]];
            self.internalSourcePicture4 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"hefeSoftLight" ofType:@"png"]]];
            self.internalSourcePicture5 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"hefeMetal" ofType:@"png"]]];
            
            
            break;
        }
            
        case IF_VALENCIA_FILTER: {
            self.internalFilter = [[IFValenciaFilter alloc] init];
            self.internalSourcePicture1 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"valenciaMap" ofType:@"png"]]];
            self.internalSourcePicture2 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"valenciaGradientMap" ofType:@"png"]]];
            
            break;
        }
            
        case IF_NASHVILLE_FILTER: {
            self.internalFilter = [[IFNashvilleFilter alloc] init];
            self.internalSourcePicture1 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"nashvilleMap" ofType:@"png"]]];
            
            break;
        }
            
        case IF_1977_FILTER: {
            self.internalFilter = [[IF1977Filter alloc] init];
            self.internalSourcePicture1 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"1977map" ofType:@"png"]]];
            self.internalSourcePicture2 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"1977blowout" ofType:@"png"]]];
            
            break;
        }
            
        case IF_LORDKELVIN_FILTER: {
            self.internalFilter = [[IFLordKelvinFilter alloc] init];
            self.internalSourcePicture1 = [[GPUImagePicture alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"kelvinMap" ofType:@"png"]]];
            
            break;
        }
            
        default:
            break;
    }
    
    [self performSelectorOnMainThread:@selector(rebuildPipleline) withObject:nil waitUntilDone:NO];
    
}

@end
