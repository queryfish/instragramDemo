//
//  FilterChooser.h
//  InstaFilters
//
//  Created by Steve on 14-3-8.
//  Copyright (c) 2014年 twitter:@diwup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImagePicture.h"
#import "IFImageFilter.h"
#import "InstaFilters.h"

@interface FilterChooser : UITableViewController

@property (nonatomic, strong) void (^doneHandler)( NSString*, NSInteger);
//@property (nonatomic, strong) GPUImagePicture* currentFilter;
@end
