//
//  ShakeToRecordTableViewController.m
//  ShakeToRecord
//
//  Created by Xoi's iMac on 2015-10-13.
//  Copyright (c) 2015 XoiAHin. All rights reserved.
//

#import "ShakeToRecordTableViewController.h"
#import <AudioToolbox/AudioToolbox.h>




@interface ShakeToRecordTableViewController ()


@property (nonatomic, strong) NSMutableArray *mediaArray;


@end



@implementation ShakeToRecordTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Library", @"Library");
    
    // Enable Edit/Done button
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    [self loadAudiofiles];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)loadAudiofiles {
    
    // Init
    _mediaArray = [[NSMutableArray alloc]init];
    
    // full path to Documents directory
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *folderPath = [paths objectAtIndex:0];
    
    NSError *errVal;
    NSArray *directoryList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:&errVal];
    
    
    for (int iX = 0; iX < [directoryList count]; iX++)
    {
        // get file name
        NSString* fileName = (NSString*)[directoryList objectAtIndex:iX];
        
        // extract file extension
        NSArray* fileNameComponents = [fileName componentsSeparatedByString:@"."];
        if ([fileNameComponents count] < 2)
            continue;
        
        NSString* fileExtension = (NSString*)[fileNameComponents objectAtIndex:([fileNameComponents count] - 1)];
        
        if (([fileExtension isEqualToString:@"mp3"]) ||
            ([fileExtension isEqualToString:@"MP3"]) ||
            ([fileExtension isEqualToString:@"M4R"]) ||
            ([fileExtension isEqualToString:@"m4r"]) ||
            ([fileExtension isEqualToString:@"m4a"]) ||
            ([fileExtension isEqualToString:@"M4A"]))
        {
            [_mediaArray addObject:fileName];
        }
    }
    
    // Sort
//    _mediaArray =[[_mediaArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
    _mediaArray  = [[[[_mediaArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] reverseObjectEnumerator] allObjects] mutableCopy];
}




#pragma mark - Detect shake gesture

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self becomeFirstResponder];
}


- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if(event.type == UIEventSubtypeMotionShake)
    {
        NSLog(@"Shake detected...");
        
        // Vibrate
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        if (self.view.hidden == YES) {
            [self.view setHidden:NO];
            [[self navigationController] setNavigationBarHidden:NO animated:YES];
            // Stop recording
        } else {
            [self.view setHidden:YES];
            [[self navigationController] setNavigationBarHidden:YES animated:YES];
            // Start recording
        }
    }
}

- (BOOL)BecomeFirstResponder
{
    return YES;
}






#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _mediaArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    
    // Configure the cell...
    NSString *fileNoExtension = [[NSString alloc]init];
    fileNoExtension = [_mediaArray objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [[fileNoExtension lastPathComponent]stringByDeletingPathExtension];
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/






@end
