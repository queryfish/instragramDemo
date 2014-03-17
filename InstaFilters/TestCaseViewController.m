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

@interface TestCaseViewController () <GPUImageRawDataProcessor,GPUImageTextureDelegate>
{
    NSURL* mediaURL;
    GPUImageMovie* sourcer;
    GPUImagePicture* stillImage;
    UIImageView * frameView;
    NSInteger currentFilterType;
}

@property (nonatomic) MPMoviePlayerController *mp;
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

@property (nonatomic, assign) IFFilterType filterIndex;
@property (nonatomic, strong) SXGPUImageMovie* movieSource;

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
    self.filter = [[IFNormalFilter alloc] init];
    self.internalFilter = self.filter;
    
    CGRect frame = self.imageView.frame;
    frame.origin = CGPointZero;
    self.gpuImageView = [[GPUImageView alloc]initWithFrame:frame];
    
    [self.filter addTarget:self.gpuImageView];
    [self.imageView addSubview:self.gpuImageView];

    self.rotationFilter = [[IFRotationFilter alloc]initWithRotation:kGPUImageRotateRight];
    self.filter = [[IFNormalFilter alloc]init];
    [self.rotationFilter addTarget:self.filter];

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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
        mediaURL = [info valueForKey:UIImagePickerControllerMediaURL];
        NSString *tempPath = NSTemporaryDirectory();
        NSString *tempFile = [tempPath stringByAppendingPathComponent:@"lastRecorder"];
    
        NSData * data = [NSData dataWithContentsOfURL:mediaURL];
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


-(void)chooseFilter:(id)sender
{
    FilterChooser* fc = [[FilterChooser alloc]initWithNibName:@"FilterChooser" bundle:nil];
    __weak typeof(self) _weakself = self;
    [fc setDoneHandler:^(NSString* filterName, NSInteger index) {
        [_weakself.filterName setText:filterName];
        _weakself.filterIndex = index;
    }];
    [self presentViewController:fc animated:YES completion:nil];
}

-(void)switchBetweenImageAndMovie:(id)sender
{
    UISwitch * switcher = sender;
    if(switcher.isOn)
    {
        self.stillImageSource = nil;
    }
    else
    {
        self.movieSource = nil;
    }
}

-(void)switchMode:(id)sender
{
    UISegmentedControl* sg = sender;
    switch (sg.selectedSegmentIndex) {
        case 0:
            [self playImage:nil];
            break;
            case 1:
            [self playFiltered:nil];
            break;
        default:
            break;
    }
}

-(void)playImage:(id)sender
{

    [self.stillImageSource processImage];
}

-(void)playFiltered:(id)sender
{
    NSURL* sampleURL = mediaURL;
    self.movieSource = [[SXGPUImageMovie alloc] initWithURL:sampleURL];
    [self.movieSource addTarget:self.rotationFilter];
    [self switchFilter:self.filterIndex];

    [self.movieSource startProcessing];
    
}

#pragma mark - Switch Filter
- (void)switchToNewFilter {
    
    if (self.stillImageSource != nil) {
        [self.stillImageSource removeTarget:self.filter];
        self.filter = self.internalFilter;
        [self.stillImageSource addTarget:self.filter];
    }
    else if(self.rotationFilter)
    {
        [self.rotationFilter removeTarget:self.filter];
        self.filter = self.internalFilter;
        [self.rotationFilter addTarget:self.filter];
    }
        
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
    
    if (self.stillImageSource != nil) {
        [self.filter addTarget:self.gpuImageView];
        [self.stillImageSource processImage];
    }
    else
    {
        [self.filter addTarget:self.gpuImageView];
        [self.movieSource startProcessing];
    }

}

- (void)switchFilter:(IFFilterType)type {
    
    if ((self.rawImage != nil) && (self.stillImageSource == nil))
    {
        // This is the state when we just switched from live view to album photo view
        self.stillImageSource = [[GPUImagePicture alloc] initWithImage:self.rawImage];
        [self.stillImageSource addTarget:self.filter];
    }
    else if(self.movieSource != nil)
    {
        
        if (currentFilterType == type) {
            return;
        }
    }
    
    [self forceSwitchToNewFilter:type];
}

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
    
    [self performSelectorOnMainThread:@selector(switchToNewFilter) withObject:nil waitUntilDone:NO];
    
}

@end
