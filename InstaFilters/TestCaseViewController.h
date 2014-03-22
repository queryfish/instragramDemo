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
    UIImagePickerController *imagePicker;
}

@property (nonatomic, strong) IBOutlet UIImageView* imageView;
@property (nonatomic, strong) IBOutlet UILabel* filterName;

@property (nonatomic, strong) IBOutlet UIButton* recorderButton;
@property (nonatomic, strong) IBOutlet UIButton* filterButton;
@property (nonatomic, strong) IBOutlet UIButton* playButton;
@property (nonatomic, strong) IBOutlet UIButton* saveButton;


-(IBAction)record:(id)sender;
-(IBAction)filter:(id)sender;

-(IBAction)play:(id)sender;
-(IBAction)save:(id)sender;

@end
