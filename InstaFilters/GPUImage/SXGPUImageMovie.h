#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "GPUImageOpenGLESContext.h"
#import "SXGPUImageOutput.h"

@interface SXGPUImageMovie : SXGPUImageOutput {
  CVPixelBufferRef _currentBuffer;
    CVOpenGLESTextureCacheRef coreVideoTextureCache; 
}

@property (readwrite, retain) NSURL *url;

-(id)initWithURL:(NSURL *)url;
-(void)startProcessing;
-(void)endProcessing;


// Manage fast texture upload
+ (BOOL)supportsFastTextureUpload;

@end
