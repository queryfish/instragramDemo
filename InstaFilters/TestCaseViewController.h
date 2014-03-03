//
//  TestCaseViewController.h
//  InstaFilters
//
//  Created by Steve on 14-3-3.
//  Copyright (c) 2014年 twitter:@diwup. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TestCaseViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    IBOutlet UIView *cameraOverlayView;
    UIImagePickerController *imagePicker;
}

@property (nonatomic, strong) IBOutlet UIImageView* imageView;

-(IBAction)recordAVideo:(id)sender;
-(IBAction)filterIt:(id)sender;
-(IBAction)playIt:(id)sender;

@end
