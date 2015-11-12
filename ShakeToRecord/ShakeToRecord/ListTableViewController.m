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
    NSString *audioDuration;
    
}


#define kDeleteButton NSLocalizedString(@"Delete", @"Delete")
#define kMoreButton NSLocalizedString(@"More", @"More")
#define kAlertActions NSLocalizedString(@"Actions", @"Actions")
#define kOnSelectedRow NSLocalizedString(@"On selected row", @"On selected row")
#define kRenameAction NSLocalizedString(@"Rename", @"Rename")
#define kCancelAction NSLocalizedString(@"Cancel", @"Cancel")
#define kShareAction NSLocalizedString(@"Share", @"Share")
#define kEnterFileName NSLocalizedString(@"Enter new file name:", @"Enter new file name:")
#define kEnter NSLocalizedString(@"Enter", @"Enter")
#define kNewName NSLocalizedString(@"New Name", @"New Name")
#define kOkay NSLocalizedString(@"OK", @"OK")



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
    
    // The reason turning this on is because at the present time, there is an issue presenting UIAlertController while in UISearchController mode...
    self.definesPresentationContext = true;
    
    shouldShowSearchResults = false;

    // full path to Documents directory
    self.paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    self.folderPath = [self.paths objectAtIndex:0];
    
    // Load files to array
    [self loadAudiofiles];
    
    [self disableAllPlaybackButtons];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    // Init timer (playback)
    self.myAudioTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];

    [self configureSearchController];
    
    self.tableView.estimatedRowHeight = 60;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)loadAudiofiles {
    
    // Init
    self.mediaArray = [[NSMutableArray alloc]init];
    
    NSError *errVal;
    NSArray *directoryList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.folderPath error:&errVal];
    
    
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
            [self.mediaArray addObject:fileName];
        }
    }
    
    // Sort
//    _mediaArray =[[_mediaArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
    self.mediaArray  = [[[[self.mediaArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] reverseObjectEnumerator] allObjects] mutableCopy];
    
    [self.tableView reloadData];
}



#pragma mark - Search Audio

- (void)configureSearchController {
    
    self.searchController = [[UISearchController alloc]initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = false;
//    self.searchController.searchBar.placeholder = @"Search here...";
    [self.searchController.searchBar setBarTintColor:[UIColor orangeColor]];
    self.searchController.searchBar.delegate = self;
    [self.searchController.searchBar sizeToFit];
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self myStopButton:nil];
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
    [self.searchController.searchBar resignFirstResponder];
}


- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    NSString *searchText = [[NSString alloc]initWithString:self.searchController.searchBar.text];
    
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchText];
    
    self.filterArray = [[self.mediaArray filteredArrayUsingPredicate:resultPredicate]mutableCopy];
    
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
    
    [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    self.myAudioRecorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:&error];
    self.myAudioRecorder.delegate = self;
    
    if (error)
    {
//        NSLog(@"error: %@", [error localizedDescription]);
    }
    
}


- (void)startRecording {
    if (!self.myAudioRecorder.recording)
    {
        [self.myAudioRecorder prepareToRecord];
        [self.myAudioRecorder record];
    }
}


- (void)stopRecording {
    
    if (self.myAudioRecorder.recording)
    {
        [self.myAudioRecorder stop];
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
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
    
    myFileName = [NSString stringWithFormat:@"%@%@%@", @"Z_", myDate, @".m4a"];
//    NSLog(@"File name is: %@", myFileName);
}






#pragma mark - Detect shake gesture

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
   
    [self.tableView reloadData];
    [self animateTable];
    [self becomeFirstResponder];
}


- (void)animateTable {
    
    NSArray *cells = [self.tableView visibleCells];
    CGFloat tableHeight = self.tableView.bounds.size.height;
    
    for (int i = 0; i < [cells count]; i++) {
        UITableViewCell *cell = [cells objectAtIndex:i];
        cell.transform = CGAffineTransformMakeTranslation(0, tableHeight);
    }
    
    for (int a = 0; a < [cells count]; a++) {
        UITableViewCell *cell = [cells objectAtIndex:a];
        [UIView animateWithDuration:1.5 delay:0.05*a usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{
            cell.transform = CGAffineTransformMakeTranslation(0, 0);
        } completion:NULL];
    }
}



- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if(event.type == UIEventSubtypeMotionShake) {
        // Stop playback if needed.
        if (self.myAudioPlayer.playing) {
            [self myStopButton:nil];
        }
        
//        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        if (self.recordButtonOutlet.enabled) {
            // Stop record and save
            self.recordButtonOutlet.enabled = false;
            [self stopRecording];
        } else {
            // Start record
            CountdownViewController *vc = [[CountdownViewController alloc]init];
            [self presentViewController:vc animated:YES completion:nil];
            [self prepareToRecord];
            self.recordButtonOutlet.enabled = true;
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
        return self.filterArray.count;
    } else {
        return self.mediaArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *fileNoExtension = nil;
    
    if (shouldShowSearchResults) {
        fileNoExtension = [self.filterArray objectAtIndex:indexPath.row];
    } else {
        fileNoExtension = [self.mediaArray objectAtIndex:indexPath.row];
    }
    
    if ([fileNoExtension isEqualToString:myLastFileName]) {
        cell.textLabel.textColor = [UIColor orangeColor];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:20.0f];
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    cell.textLabel.text = [[fileNoExtension lastPathComponent]stringByDeletingPathExtension];
    
    // Retrieve audio duration
    NSString *getAudioPath = [self.folderPath stringByAppendingPathComponent:fileNoExtension];
    NSURL *finalUrl=[[NSURL alloc]initFileURLWithPath:getAudioPath];
//    NSLog(@"finalUrl===%@",finalUrl);
    
    AVURLAsset* audioAsset = [AVURLAsset URLAssetWithURL:finalUrl options:nil];
    CMTime durationOfAudio = audioAsset.duration;
    float audioDurationSeconds = CMTimeGetSeconds(durationOfAudio);
//    NSLog(@"duration==%2f",audioDurationSeconds);
    
    int myMinutes = floor(audioDurationSeconds/60);
    int mySeconds = trunc(audioDurationSeconds - myMinutes * 60);
    
    if (mySeconds < 10) {
        audioDuration = [NSString stringWithFormat:@"%i:0%i", myMinutes, mySeconds];
    } else {
        audioDuration = [NSString stringWithFormat:@"%i:%i", myMinutes, mySeconds];
    }
    cell.detailTextLabel.text = audioDuration;
    
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
    
    if (shouldShowSearchResults) {
        selectedAudio = [self.filterArray objectAtIndex:indexPath.row];
    } else {
        selectedAudio = [self.mediaArray objectAtIndex:indexPath.row];
    }

    
    // Delete action
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:kDeleteButton handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        
        NSString *fullFileName = [NSString stringWithFormat:@"%@/%@", self.folderPath, selectedAudio];
        [[NSFileManager defaultManager] removeItemAtPath:fullFileName error: NULL];
        
        // Remove from table view
        if (shouldShowSearchResults) {
            [self.filterArray removeObjectAtIndex:indexPath.row];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [self.mediaArray removeObjectAtIndex:indexPath.row];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        
        [self loadAudiofiles];
    }];
    deleteAction.backgroundColor = [UIColor redColor];
    
    
    // More actions
    UITableViewRowAction *moreAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:kMoreButton handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        // show UIActionSheet
        [self performAlertController];
    }];
    moreAction.backgroundColor = [UIColor orangeColor];
    
    return @[deleteAction, moreAction];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.activityIndicator startAnimating];
    
    selectedAudio = nil;
    if (shouldShowSearchResults) {
        selectedAudio = [self.filterArray objectAtIndex:indexPath.row];
        [self.searchController.searchBar resignFirstResponder];
    } else {
        selectedAudio = [self.mediaArray objectAtIndex:indexPath.row];
    }
    
    [self myPlayButton:nil];

//    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.myAudioPlayer.playing) {
        [self myStopButton:nil];
    }
}



#pragma mark - Action Sheet

- (void)performAlertController {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:kAlertActions message:kOnSelectedRow preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *rename = [UIAlertAction actionWithTitle:kRenameAction style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self renameAudioFile];
    }];
    [alertController addAction:rename];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:kCancelAction style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancel];
    
    UIAlertAction *share = [UIAlertAction actionWithTitle:kShareAction style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self shareAudioFile];
    }];
    [alertController addAction:share];
    
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}


- (void)shareAudioFile {
    
    NSArray *pathComponents = [NSArray arrayWithObjects: [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               selectedAudio, nil];
    NSURL *audioFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    NSArray *objectsToShare = @[audioFileURL];
    
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    
    // Exclude some activities.
    NSArray *excludedActivities = @[UIActivityTypePostToTwitter,
//                                    UIActivityTypePostToFacebook,
                                    UIActivityTypePostToWeibo,
//                                    UIActivityTypeMessage,
//                                    UIActivityTypeMail,
                                    UIActivityTypePrint,
                                    UIActivityTypeCopyToPasteboard,
                                    UIActivityTypeAssignToContact,
                                    UIActivityTypeSaveToCameraRoll,
                                    UIActivityTypeAddToReadingList,
                                    UIActivityTypePostToFlickr,
                                    UIActivityTypePostToVimeo,
                                    UIActivityTypePostToTencentWeibo];
    
    controller.excludedActivityTypes = excludedActivities;
    
    // Present the controller
    [self presentViewController:controller animated:YES completion:nil];
}


- (void)renameAudioFile {
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:kRenameAction
                                          message:kEnterFileName
                                          preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *rename = [UIAlertAction
                             actionWithTitle:kEnter
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action) {
                                 
                                 NSString *myNewFileName = ((UITextField *)[alertController.textFields objectAtIndex:0]).text;
                                 // Rename
                                 NSString *myExt = nil;
                                 myExt = [selectedAudio pathExtension];
                                 
                                 NSString *myFinalName = nil;
                                 myFinalName = [NSString stringWithFormat:@"%@%@%@", myNewFileName, @".", myExt];
                                 
                                 NSString *filePathSrc = [self.folderPath stringByAppendingPathComponent:selectedAudio];
                                 NSString *filePathDst = [self.folderPath stringByAppendingPathComponent:myFinalName];
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
                                 
                                 if (shouldShowSearchResults) {
                                     self.searchController.active = false;
                                     [self.searchController.searchBar resignFirstResponder];
                                     shouldShowSearchResults = false;
                                 }
                                 
                                 myLastFileName = myFinalName;
                                 [self loadAudiofiles];
    }];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:kCancelAction
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    [alertController addAction:rename];
    [alertController addAction:cancel];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = kNewName;
    }];
    
    [self presentViewController:alertController animated:YES completion:nil];
}



#pragma mark - Audio Playback



- (void)disableAllPlaybackButtons {
    self.playButtonOutlet.enabled = false;
    self.pauseButtonOutlet.enabled = false;
    self.stopButtonOutlet.enabled = false;
    self.positionSlider.enabled = false;
   
}



- (void)playbackSetUp {
    
    // Path for audio file
    NSString *sourceFile = [self.folderPath stringByAppendingString:[NSString stringWithFormat:@"/%@", selectedAudio]];
    
    // Use GCD to load audio in the background
    dispatch_queue_t dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(dispatchQueue, ^(void) {
        
        NSData *fileData=[NSData dataWithContentsOfFile:sourceFile];
        
        NSError *error = nil;
        self.myAudioPlayer = [[AVAudioPlayer alloc] initWithData:fileData error:&error];
        
        self.positionSlider.maximumValue = self.myAudioPlayer.duration;
        self.positionSlider.minimumValue = 0;
        self.myAudioPlayer.currentTime = self.positionSlider.value;
        
        if (self.myAudioPlayer != nil){
            /* Set the delegate and start playing */
            self.myAudioPlayer.delegate = self;
            
            if ([self.myAudioPlayer prepareToPlay] && [self.myAudioPlayer play]) {

                if (self.myAudioTimer == nil) {
                    self.myAudioTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
                }

            } else{
//                NSLog(@"Failed to play...");
            }
        } else {
//            NSLog(@"Failed to instantiate AVAudioPlayer...");
        }
    });
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
//    NSLog(@"Finished playing the song");
    if ([player isEqual:self.myAudioPlayer]){
         self.myAudioPlayer = nil;
    }
    
    if (self.activityIndicator.isAnimating) {
        [self.activityIndicator stopAnimating];
    }
    
    [self disableAllPlaybackButtons];
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player{
    /* Audio Session is interrupted. The player will be paused here */
}

- (void) audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags {
    
    if (flags == AVAudioSessionInterruptionOptionShouldResume && player != nil) {
        [player play];
    }
}


- (IBAction)changePosition:(UISlider *)sender {
    self.myAudioPlayer.currentTime = self.positionSlider.value;
}

- (IBAction)myPlayButton:(UIBarButtonItem *)sender {
    
    if (!self.myAudioPlayer) {
        [self playbackSetUp];
    }
    
    [self.activityIndicator startAnimating];
    
    self.playButtonOutlet.enabled = false;
    self.pauseButtonOutlet.enabled = true;
    self.stopButtonOutlet.enabled = true;
    self.positionSlider.enabled = true;
    
    [self.myAudioPlayer play];
    
    if (self.myAudioTimer ==nil) {
        self.myAudioTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
    }
}

- (IBAction)myPauseButton:(UIBarButtonItem *)sender {
    [self.myAudioPlayer pause];
    
    [self.myAudioTimer invalidate];
    self.myAudioTimer = nil;
    
    if (self.activityIndicator.isAnimating) {
        [self.activityIndicator stopAnimating];
    }
    
    self.playButtonOutlet.enabled = true;
    self.pauseButtonOutlet.enabled = false;
    self.stopButtonOutlet.enabled = true;
}

- (IBAction)myStopButton:(UIBarButtonItem *)sender {
    [self.myAudioPlayer stop];
    self.myAudioPlayer = nil;
    
    [self.myAudioPlayer setCurrentTime:0];
    self.positionSlider.value = self.myAudioPlayer.currentTime;
    [self.myAudioTimer invalidate];
    self.myAudioTimer = nil;
    
    if (self.activityIndicator.isAnimating) {
        [self.activityIndicator stopAnimating];
    }
    
    [self disableAllPlaybackButtons];
}

//- (IBAction)infoButton:(UIBarButtonItem *)sender {
//    
//    [self getDuration];
//    
//    UIAlertController *alertController = [UIAlertController
//                                          alertControllerWithTitle:selectedAudio
//                                          message:audioDuration
//                                          preferredStyle:UIAlertControllerStyleAlert];
//    
//    UIAlertAction* cancel = [UIAlertAction actionWithTitle:kOkay
//                                                     style:UIAlertActionStyleCancel
//                                                   handler:nil];
//    [alertController addAction:cancel];
//    [self presentViewController:alertController animated:YES completion:nil];
//}

- (void)updateSlider {
    [self.positionSlider setValue:self.myAudioPlayer.currentTime];
}


//- (void)getDuration {
//    
//    audioDuration = @"";
//    double myDuration = self.myAudioPlayer.duration;
//    
//    int myMinutes = floor(myDuration/60);
//    int mySeconds = trunc(myDuration - myMinutes * 60);
//    
//    if (mySeconds < 10) {
//        audioDuration = [NSString stringWithFormat:@"%i:0%i", myMinutes, mySeconds];
//    } else {
//        audioDuration = [NSString stringWithFormat:@"%i:%i", myMinutes, mySeconds];
//    }
//}













@end
