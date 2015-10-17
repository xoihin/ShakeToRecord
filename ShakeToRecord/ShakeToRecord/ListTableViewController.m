//
//  ShakeToRecordTableViewController.m
//  ShakeToRecord
//
//  Created by Xoi's iMac on 2015-10-13.
//  Copyright (c) 2015 XoiAHin. All rights reserved.
//

#import "ListTableViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "CountdownViewController.h"
#import <MediaPlayer/MediaPlayer.h>


@interface ListTableViewController () <AVAudioRecorderDelegate, AVAudioPlayerDelegate, UISearchResultsUpdating, UISearchBarDelegate>
{
    NSString *myFileName;
    NSString *myLastFileName;
    NSString *selectedAudio;
    BOOL shouldShowSearchResults;
    
}

@property (nonatomic, strong) NSMutableArray *mediaArray;
@property (nonatomic, strong) NSMutableArray *filterArray;

@property (nonatomic, strong) AVAudioRecorder *myAudioRecorder;
@property (nonatomic, strong) AVAudioPlayer *myAudioPlayer;

@property (nonatomic, strong) NSArray *paths;
@property (nonatomic, strong) NSString *folderPath;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) UISearchController *searchController;


@end



@implementation ListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Library", @"Library");
    
    shouldShowSearchResults = false;
    
    // Enable Edit/Done button
//    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    // full path to Documents directory
    _paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _folderPath = [_paths objectAtIndex:0];
    
    // Load files to array
    [self loadAudiofiles];
    
    _playButtonOutlet.enabled = false;
    _pauseButtonOutlet.enabled = false;
    _stopButtonOutlet.enabled = false;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    [self configureSearchController];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)loadAudiofiles {
    
    // Init
    _mediaArray = [[NSMutableArray alloc]init];
    
    NSError *errVal;
    NSArray *directoryList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_folderPath error:&errVal];
    
    
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
            ([fileExtension isEqualToString:@"CAF"]) ||
            ([fileExtension isEqualToString:@"caf"]) ||
            ([fileExtension isEqualToString:@"m4a"]) ||
            ([fileExtension isEqualToString:@"M4A"]))
        {
            [_mediaArray addObject:fileName];
        }
    }
    
    // Sort
//    _mediaArray =[[_mediaArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
    _mediaArray  = [[[[_mediaArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] reverseObjectEnumerator] allObjects] mutableCopy];
    
    [self.tableView reloadData];
}



#pragma mark - Search Audio

- (void)configureSearchController {
    _searchController = [[UISearchController alloc]initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.dimsBackgroundDuringPresentation = false;
    _searchController.searchBar.placeholder = @"Search here...";
    _searchController.searchBar.delegate = self;
    [_searchController.searchBar sizeToFit];
    
    self.tableView.tableHeaderView = _searchController.searchBar;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    shouldShowSearchResults = true;
    [self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    shouldShowSearchResults = false;
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if (!shouldShowSearchResults) {
        shouldShowSearchResults = true;
        [self.tableView reloadData];
    }
    [_searchController.searchBar resignFirstResponder];
}


- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    NSString *searchText = [[NSString alloc]initWithString:_searchController.searchBar.text];
    
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchText];
    
    _filterArray = [[_mediaArray filteredArrayUsingPredicate:resultPredicate]mutableCopy];
    
    [self.tableView reloadData];
}





#pragma mark - Audio Recording


- (void)prepareToRecord {
    
    [self myAudioName];
    
    myLastFileName = myFileName;

    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               myFileName, nil];
    
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Setup audio session
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    _myAudioRecorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:&error];
    _myAudioRecorder.delegate = self;
    
    if (error)
    {
        NSLog(@"error: %@", [error localizedDescription]);
    }
    
}


- (void)startRecording {
    if (!_myAudioRecorder.recording)
    {
        [_myAudioRecorder prepareToRecord];
        [_myAudioRecorder record];
    }
}


- (void)stopRecording {
    
    if (_myAudioRecorder.recording)
    {
        [_myAudioRecorder stop];
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive:NO error:nil];
        
        [self loadAudiofiles];
    }
}


- (void)myAudioName {
    
    myFileName = @"";
    
    NSDate *myCurrentdate = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyyMMdd_HHmmss"];
    NSString *myDate = [dateFormat stringFromDate: myCurrentdate];
    
    myFileName = [NSString stringWithFormat:@"%@%@%@", @"z_", myDate, @".m4a"];
//    NSLog(@"File name is: %@", myFileName);
}






#pragma mark - Detect shake gesture

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self becomeFirstResponder];
}


- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if(event.type == UIEventSubtypeMotionShake) {
        // Stop playback if needed.
        if (_myAudioPlayer.playing) {
            [self myStopButton:nil];
        }
        
        if (self.view.hidden == YES) {
            [self.view setHidden:NO];
            [[self navigationController] setNavigationBarHidden:NO animated:YES];
            [[self navigationController] setToolbarHidden:NO];
            // Stop recording
            [self stopRecording];
             AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        } else {
             AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            
            CountdownViewController *vc = [[CountdownViewController alloc]init];
            [self presentViewController:vc animated:YES completion:nil];
            
            [self prepareToRecord];
            
            [self.view setHidden:YES];
            [[self navigationController] setNavigationBarHidden:YES animated:YES];
            [[self navigationController] setToolbarHidden:YES];
            // Start recording
            [self startRecording];
        }
    }
}

- (BOOL)BecomeFirstResponder {
    return YES;
}






#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (shouldShowSearchResults) {
        return _filterArray.count;
    } else {
        return _mediaArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *fileNoExtension = [[NSString alloc]init];
    
    if (shouldShowSearchResults) {
        fileNoExtension = [_filterArray objectAtIndex:indexPath.row];
    } else {
        fileNoExtension = [_mediaArray objectAtIndex:indexPath.row];
    }
    
    if ([fileNoExtension isEqualToString:myLastFileName]) {
        cell.textLabel.textColor = [UIColor orangeColor];
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    cell.textLabel.text = [[fileNoExtension lastPathComponent]stringByDeletingPathExtension];
    
    return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Obtain audio name
    selectedAudio = [[NSString alloc]init];
    selectedAudio = [_mediaArray objectAtIndex:indexPath.row];

    // Delete action
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Delete" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        
        NSString *fullFileName = [NSString stringWithFormat:@"%@/%@", _folderPath, selectedAudio];
        [[NSFileManager defaultManager] removeItemAtPath:fullFileName error: NULL];
        
        // Remove from table view
        [_mediaArray removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }];
    deleteAction.backgroundColor = [UIColor redColor];
    
    
    // More actions
    UITableViewRowAction *moreAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"More" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        // show UIActionSheet
        [self performAlertController];
    }];
    moreAction.backgroundColor = [UIColor orangeColor];
    
    return @[deleteAction, moreAction];
}

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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    selectedAudio = nil;
    
    [self.activityIndicator startAnimating];
    
    if (!_myAudioPlayer.playing) {
        selectedAudio = [_mediaArray objectAtIndex:indexPath.row];
        [self myPlayButton:nil];
    }
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_myAudioPlayer.playing) {
        [self myStopButton:nil];
    }
}


#pragma mark - Action Sheet

- (void)performAlertController {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Actions" message:@"Perform on row" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *rename = [UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self renameAudioFile];
    }];
    [alertController addAction:rename];
    
    UIAlertAction *share = [UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self shareAudioFile];
    }];
    [alertController addAction:share];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancel];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)shareAudioFile {
    
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               selectedAudio, nil];
    NSURL *audioFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    NSArray *objectsToShare = @[audioFileURL];
    
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    
    // Exclude all activities except AirDrop.
    NSArray *excludedActivities = @[UIActivityTypePostToTwitter, UIActivityTypePostToFacebook,
                                    UIActivityTypePostToWeibo,
                                    UIActivityTypeMessage, UIActivityTypeMail,
                                    UIActivityTypePrint, UIActivityTypeCopyToPasteboard,
                                    UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll,
                                    UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr,
                                    UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo];
    controller.excludedActivityTypes = excludedActivities;
    
    // Present the controller
    [self presentViewController:controller animated:YES completion:nil];
}


- (void)renameAudioFile {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"File Name"
                                                        message:@"Enter the file name:"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Ok", nil];
    
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    [alertView show];
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {  //File name entered...
        
        UITextField *myNewFileName = [alertView textFieldAtIndex:0];
        
        // Rename
        NSString *myExt = [[NSString alloc]init];
        myExt = [selectedAudio pathExtension];
        
        NSString *myFinalName = [[NSString alloc]init];
        myFinalName = [NSString stringWithFormat:@"%@%@%@", myNewFileName.text, @".", myExt];
        
        NSString *filePathSrc = [_folderPath stringByAppendingPathComponent:selectedAudio];
        NSString *filePathDst = [_folderPath stringByAppendingPathComponent:myFinalName];
        NSFileManager *manager = [NSFileManager defaultManager];
        if ([manager fileExistsAtPath:filePathSrc]) {
            
            NSError *error = nil;
            [manager moveItemAtPath:filePathSrc toPath:filePathDst error:&error];
            
            if (error) {
                NSLog(@"There is an Error: %@", error);
            }
        } else {
            NSLog(@"File %@ doesn't exists", selectedAudio);
        }
        [self loadAudiofiles];
    
    }
}



#pragma mark - Audio Playback


- (void)playbackSetUp {
    
    // Path for audio file
    NSString *sourceFile = [_folderPath stringByAppendingString:[NSString stringWithFormat:@"/%@", selectedAudio]];
    
    // Use GCD to load audio in the background
    dispatch_queue_t dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(dispatchQueue, ^(void) {
        
        NSData *fileData=[NSData dataWithContentsOfFile:sourceFile];
        
        NSError *error = nil;
        _myAudioPlayer = [[AVAudioPlayer alloc] initWithData:fileData error:&error];
        
        if (_myAudioPlayer != nil){
            /* Set the delegate and start playing */
            _myAudioPlayer.delegate = self;
            
            if ([_myAudioPlayer prepareToPlay] && [_myAudioPlayer play]) {
//                [_myAudioPlayer play];
                [self.activityIndicator stopAnimating];
            } else{
                NSLog(@"Failed to play...");
            }
        } else {
            NSLog(@"Failed to instantiate AVAudioPlayer...");
        }
    });
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
//    NSLog(@"Finished playing the song");
    
    if ([player isEqual:_myAudioPlayer]){
         _myAudioPlayer = nil;
    }
    
    _playButtonOutlet.enabled = false;
    _pauseButtonOutlet.enabled = false;
    _stopButtonOutlet.enabled = false;
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player{
    /* Audio Session is interrupted. The player will be paused here */
}

- (void) audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags {
    
    if (flags == AVAudioSessionInterruptionOptionShouldResume && player != nil) {
        [player play];
    }
}



- (IBAction)myPlayButton:(UIBarButtonItem *)sender {
    
    if (!_myAudioPlayer) {
        [self playbackSetUp];
    }
    
    _playButtonOutlet.enabled = false;
    _pauseButtonOutlet.enabled = true;
    _stopButtonOutlet.enabled = true;
    
    [_myAudioPlayer play];
}

- (IBAction)myPauseButton:(UIBarButtonItem *)sender {
    [_myAudioPlayer pause];
    
    _playButtonOutlet.enabled = true;
    _pauseButtonOutlet.enabled = false;
    _stopButtonOutlet.enabled = true;
}

- (IBAction)myStopButton:(UIBarButtonItem *)sender {
    [_myAudioPlayer stop];
    _myAudioPlayer = nil;
    
    _playButtonOutlet.enabled = false;
    _pauseButtonOutlet.enabled = false;
    _stopButtonOutlet.enabled = false;
    
}



























@end
