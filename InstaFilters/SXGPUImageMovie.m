#import "SXGPUImageMovie.h"

@implementation SXGPUImageMovie

@synthesize url = _url;


- (void)dealloc
{
    
    if ([SXGPUImageMovie supportsFastTextureUpload])
    {
        CFRelease(coreVideoTextureCache);
    }
}

#pragma mark -
#pragma mark Manage fast texture upload

+ (BOOL)supportsFastTextureUpload;
{
    return (CVOpenGLESTextureCacheCreate != NULL);
}


-(id)initWithURL:(NSURL *)url {
  if (!(self = [super init])) {
    return nil;
  }
  
  self.url = url;
    
    if ([SXGPUImageMovie supportsFastTextureUpload])
    {
        [GPUImageOpenGLESContext useImageProcessingContext];
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge CVEAGLContext)((__bridge void *)[[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] context]), NULL, &coreVideoTextureCache);
        if (err)
        {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d",err);
        }
        
        // Need to remove the initially created texture
        [self deleteOutputTexture];
    }
    
  
  return self;
}

-(void)startProcessing {
  // AVURLAsset to read input movie (i.e. mov recorded to local storage)
  NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
  AVURLAsset *inputAsset = [[AVURLAsset alloc] initWithURL:self.url options:inputOptions];
  
  // Load the input asset tracks information
  [inputAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler: ^{
    NSError *error = nil;
    // Check status of "tracks", make sure they were loaded    
    AVKeyValueStatus tracksStatus = [inputAsset statusOfValueForKey:@"tracks" error:&error];
    if (!tracksStatus == AVKeyValueStatusLoaded) {
      // failed to load
      return;
    }
    /* Read video samples from input asset video track */
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:inputAsset error:&error];
    
    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    [outputSettings setObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]  forKey: (NSString*)kCVPixelBufferPixelFormatTypeKey];
      
    AVAssetReaderTrackOutput *readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[inputAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:outputSettings];
        
    // Assign the tracks to the reader and start to read
    [reader addOutput:readerVideoTrackOutput];
    if ([reader startReading] == NO) {
      // Handle error
      NSLog(@"Error reading");
    }
    
    while (reader.status == AVAssetReaderStatusReading)
    {
      CMSampleBufferRef sampleBufferRef = [readerVideoTrackOutput copyNextSampleBuffer];
      if (sampleBufferRef) {
        CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
        _currentBuffer = pixelBuffer;
        [self performSelectorOnMainThread:@selector(processFrame) withObject:nil waitUntilDone:YES];
        CMSampleBufferInvalidate(sampleBufferRef);
        CFRelease(sampleBufferRef);
      }
    }
    if(self.doneHandler)
        self.doneHandler();
  }];
}

-(void)processFrame{
    int bufferWidth = CVPixelBufferGetWidth(_currentBuffer);
    int bufferHeight = CVPixelBufferGetHeight(_currentBuffer);
//    NSLog(@"Frame Size w@%d h@%d",bufferWidth,bufferHeight);
    
    if ([SXGPUImageMovie supportsFastTextureUpload])
    {
        //Test for movie frame YUV color format
        if (CVPixelBufferGetPlaneCount(_currentBuffer) > 0) // Check for YUV planar inputs to do RGB conversion
        {
            NSAssert(0, @"Tested it.");
        }

        CVPixelBufferLockBaseAddress(_currentBuffer, 0);
        
        [GPUImageOpenGLESContext useImageProcessingContext];
        CVOpenGLESTextureRef texture = NULL;
        CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, _currentBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, bufferWidth, bufferHeight, GL_BGRA, GL_UNSIGNED_BYTE, 0, &texture);
        
        if (!texture || err) {
            NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err);
            return;
        }
        
        outputTexture = CVOpenGLESTextureGetName(texture);
        glBindTexture(CVOpenGLESTextureGetTarget(texture), outputTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        for (id<GPUImageInput> currentTarget in targets)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            [currentTarget setInputTexture:outputTexture atIndex:[[targetTextureIndices objectAtIndex:indexOfObject] integerValue]];
            
            [currentTarget setInputSize:CGSizeMake(bufferWidth, bufferHeight)];
            [currentTarget newFrameReady];
        }
        
        CVPixelBufferUnlockBaseAddress(_currentBuffer, 0);
        
        glBindTexture(outputTexture, 0);
        
        // Flush the CVOpenGLESTexture cache and release the texture
        CVOpenGLESTextureCacheFlush(coreVideoTextureCache, 0);
        CFRelease(texture);
        outputTexture = 0;
    }
}

//The Else part
-(void)processFrame2 {
  // Upload to texture
  CVPixelBufferLockBaseAddress(_currentBuffer, 0);
  int bufferHeight = CVPixelBufferGetHeight(_currentBuffer);
  int bufferWidth = CVPixelBufferGetWidth(_currentBuffer);
  
  glBindTexture(GL_TEXTURE_2D, outputTexture);
  // Using BGRA extension to pull in video frame data directly
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferWidth, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(_currentBuffer));
  
  CGSize currentSize = CGSizeMake(bufferWidth, bufferHeight);
  for (id<GPUImageInput> currentTarget in targets)
  {
    [currentTarget setInputSize:currentSize];
    [currentTarget newFrameReady];
  }
  CVPixelBufferUnlockBaseAddress(_currentBuffer, 0);
}



-(void)endProcessing {
  
}

@end
