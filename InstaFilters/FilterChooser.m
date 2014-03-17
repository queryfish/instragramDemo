//
//  FilterChooser.m
//  InstaFilters
//
//  Created by Steve on 14-3-8.
//  Copyright (c) 2014年 twitter:@diwup. All rights reserved.
//

#import "FilterChooser.h"

@interface FilterChooser ()
{
    NSInteger selectedIndex;
}

@property (nonatomic, strong) NSArray* filterTypeNames;
@property (nonatomic, strong) NSArray* imageNames;
@end

@implementation FilterChooser

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    selectedIndex = 0;
    self.filterTypeNames = @[
                            @"Normal",
                            @"Amaro",
                            @"Rise",
                            @"Hudson",
                            @"XproII",
                            @"SierrA",
                            @"LoMoFi",
                            @"EarlyBird",
                            @"SuTro",
                            @"ToasTer",
                            @"Brannan",
                            @"InkWell",
                            @"WalDen",
                            @"HeFe",
                            @"Valencia",
                            @"NashVille",
                            @"1977",
                            @"LordKelvin"
                            ];
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filterTypeNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier ];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    // Configure the cell...
    [[cell textLabel] setText:_filterTypeNames[indexPath.row]];
//    if (indexPath.row ==  selectedIndex) {
//        [[cell textLabel] setTextColor:[UIColor blueColor]];
//    }
//    else
//    {
        [[cell textLabel] setTextColor:[UIColor grayColor]];
//    }
//    NSString* imageName = self.imageNames[indexPath.row];
//    [[cell imageView] setImage:[UIImage imageNamed:imageName]];
    UIImageView* filterImageView = [cell imageView];
    switch ([indexPath row]) {
        case 0: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTileNormal" ofType:@"png"]];
            
            break;
        }
        case 1: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTileAmaro" ofType:@"png"]];
            
            break;
        }
        case 2: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTileRise" ofType:@"png"]];
            
            break;
        }
        case 3: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTileHudson" ofType:@"png"]];
            
            break;
        }
        case 4: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTileXpro2" ofType:@"png"]];
            
            break;
        }
        case 5: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTileSierra" ofType:@"png"]];
            
            break;
        }
        case 6: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTileLomoFi" ofType:@"png"]];
            
            break;
        }
        case 7: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTileEarlybird" ofType:@"png"]];
            
            break;
        }
        case 8: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTileSutro" ofType:@"png"]];
            
            break;
        }
        case 9: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTileToaster" ofType:@"png"]];
            
            break;
        }
        case 10: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTileBrannan" ofType:@"png"]];
            
            break;
        }
        case 11: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTileInkwell" ofType:@"png"]];
            
            break;
        }
        case 12: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTileWalden" ofType:@"png"]];
            
            break;
        }
        case 13: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTileHefe" ofType:@"png"]];
            
            break;
        }
        case 14: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTileValencia" ofType:@"png"]];
            
            break;
        }
        case 15: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTileNashville" ofType:@"png"]];
            
            break;
        }
        case 16: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTile1977" ofType:@"png"]];
            
            break;
        }
        case 17: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTileLordKelvin" ofType:@"png"]];
            break;
        }
            
        default: {
            filterImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DSFilterTileNormal" ofType:@"png"]];
            
            break;
        }
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    selectedIndex = indexPath.row;
    if (self.doneHandler) {
        self.doneHandler(self.filterTypeNames[indexPath.row], selectedIndex);
    }

    [self dismissModalViewControllerAnimated:YES];
}

@end
