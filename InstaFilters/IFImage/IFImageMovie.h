//
//  IFImageMovie.h
//  InstaFilters
//
//  Created by Steve on 14-3-5.
//  Copyright (c) 2014年 twitter:@diwup. All rights reserved.
//

#import "GPUImageMovie.h"
#import "GPUImage.h"

@interface IFImageMovie : GPUImageMovie

@property (strong, nonatomic) GPUImageView *gpuImageView;
@property (nonatomic, unsafe_unretained, readonly) BOOL isRecordingMovie;

- (void)startRecordingMovie;
- (void)stopRecordingMovie;

@end
