#import "GPUImageFilter.h"
#import "GPUImageContext.h"
//typedef enum { kGPUImageRotateLeft, kGPUImageRotateRight, kGPUImageFlipVertical, kGPUImageFlipHorizonal} GPUImageRotationMode;

@interface GPUImageRotationFilter : GPUImageFilter
{
    GPUImageRotationMode rotationMode;
}

// Initialization and teardown
- (id)initWithRotation:(GPUImageRotationMode)newRotationMode;

@end
