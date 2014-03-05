//
//  IFImageMovie.m
//  InstaFilters
//
//  Created by Steve on 14-3-5.
//  Copyright (c) 2014年 twitter:@diwup. All rights reserved.
//

#import "IFImageMovie.h"
#import "InstaFilters.h"

@interface IFImageMovie ()

@property (nonatomic, strong) IFImageFilter *filter;
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

@property (nonatomic, strong) IFRotationFilter *rotationFilter;
@property (nonatomic, unsafe_unretained) IFFilterType currentFilterType;

@property (nonatomic, unsafe_unretained) dispatch_queue_t prepareFilterQueue;

//@property (nonatomic, strong) GPUImagePicture *stillImageSource;
//@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;

@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;
@property (nonatomic, unsafe_unretained, readwrite) BOOL isRecordingMovie;
//@property (nonatomic, strong) AVAudioRecorder *soundRecorder;
@property (nonatomic, strong) AVMutableComposition *mutableComposition;
@property (nonatomic, strong) AVAssetExportSession *assetExportSession;

- (void)switchToNewFilter;
- (void)forceSwitchToNewFilter:(IFFilterType)type;

- (BOOL)canStartRecordingMovie;
- (void)removeFile:(NSURL *)fileURL;
- (NSURL *)fileURLForTempMovie;
- (void)initializeSoundRecorder;
- (NSURL *)fileURLForTempSound;
- (void)startRecordingSound;
- (void)prepareToRecordSound;
- (void)stopRecordingSound;
- (void)combineSoundAndMovie;
- (NSURL *)fileURLForFinalMixedAsset;

- (void)focusAndLockAtPoint:(CGPoint)point;
- (void)focusAndAutoContinuousFocusAtPoint:(CGPoint)point;
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
@end

@implementation IFImageMovie

@synthesize filter;
@synthesize sourcePicture1;
@synthesize sourcePicture2;
@synthesize sourcePicture3;
@synthesize sourcePicture4;
@synthesize sourcePicture5;

@synthesize internalFilter;
@synthesize internalSourcePicture1;
@synthesize internalSourcePicture2;
@synthesize internalSourcePicture3;
@synthesize internalSourcePicture4;
@synthesize internalSourcePicture5;

@synthesize gpuImageView;
@synthesize rotationFilter;
@synthesize currentFilterType;
@synthesize prepareFilterQueue;
//@synthesize rawImage;
//@synthesize stillImageSource;

//@synthesize stillImageOutput;

//@synthesize delegate;

@synthesize movieWriter;
@synthesize isRecordingMovie;
//@synthesize soundRecorder;
@synthesize mutableComposition;
@synthesize assetExportSession;

#pragma mark - Save current image
//- (void)saveCurrentStillImage {
//    if (self.rawImage == nil) {
//        return;
//    }
//    // If without the rorating 0 degree action, the image will be left hand 90 degrees rorated.
//    UIImageWriteToSavedPhotosAlbum([[self.filter imageFromCurrentlyProcessedOutput] imageRotatedByDegrees:0], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
//}


#pragma mark - Mixed sound and movie asset url
- (NSURL *)fileURLForFinalMixedAsset {
    static NSURL *tempMixedAssetURL = nil;
    
    @synchronized(self) {
        if (tempMixedAssetURL == nil) {
            tempMixedAssetURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"tempMix.m4v"]];
        }
    }
    
    return tempMixedAssetURL;
}




#pragma mark - Movie & image did saved callback
//- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *) error contextInfo:(void *) contextInfo {
//    
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Saved" message:@"The video was saved in Camera Roll." delegate:nil cancelButtonTitle:@"Sweet" otherButtonTitles:nil];
//    [alertView show];
//    if ([self.delegate respondsToSelector:@selector(IFVideoCameraDidFinishProcessingMovie:)]) {
//        [self.delegate IFVideoCameraDidFinishProcessingMovie:self];
//    }
//    [self startCameraCapture];
//    [self focusAndAutoContinuousFocusAtPoint:CGPointMake(.5f, .5f)];
//}




#pragma mark - Movie Writing methods
- (void)startRecordingMovie {
//    if ([self canStartRecordingMovie] == NO) {
//        return;
//    }
//    if (self.isRecordingMovie == YES) {
//        return;
//    }
    self.isRecordingMovie = YES;
//    [self focusAndLockAtPoint:CGPointMake(.5f, .5f)];
//    [self removeFile:[self fileURLForTempMovie]];
    self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:[self fileURLForTempMovie] size:CGSizeMake(480.0f, 480.0f)];
    [self.filter addTarget:movieWriter];
    [self.movieWriter startRecording];
    [self startProcessing];
}

- (void)stopRecordingMovie
{
    [self.filter removeTarget:self.movieWriter];
    [self.movieWriter finishRecording];
    self.isRecordingMovie = NO;
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

- (NSURL *)fileURLForTempMovie {
    static NSURL *tempMoviewURL = nil;
    
    @synchronized(self) {
        if (tempMoviewURL == nil) {
            tempMoviewURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"temp.m4v"]];
        }
    }
    
    return tempMoviewURL;
}


#pragma mark - Proper Size For Resizing Large Image
- (CGSize)properSizeForResizingLargeImage:(UIImage *)originaUIImage {
    float originalWidth = originaUIImage.size.width;
    float originalHeight = originaUIImage.size.height;
    float smallerSide = 0.0f;
    float scalingFactor = 0.0f;
    
    if (originalWidth < originalHeight) {
        smallerSide = originalWidth;
        scalingFactor = 640.0f / smallerSide;
        return CGSizeMake(640.0f, originalHeight*scalingFactor);
    } else {
        smallerSide = originalHeight;
        scalingFactor = 640.0f / smallerSide;
        return CGSizeMake(originalWidth*scalingFactor, 640.0f);
    }
}

#pragma mark - init

-(instancetype)initWithURL:(NSURL *)url
{
    self = [super initWithURL:url];
    if(self)
    {

        [self addTarget:self.filter];

        [self.filter addTarget:self.gpuImageView];

        // In addition to displaying to the screen, write out a processed version of the movie to disk
        NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
        unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
        NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
        
        movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(640.0, 480.0)];
        [self.filter addTarget:movieWriter];
        
        [movieWriter startRecording];
        

    }
}

@end
