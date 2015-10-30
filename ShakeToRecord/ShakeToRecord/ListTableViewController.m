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


@interface ListTableViewController () <AVAudioRecorderDelegate, AVAudioPlayerDelegate>
{
    NSString *myFileName;
    NSString *myLastFileName;
    NSString *selectedAudio;
}

@property (nonatomic, strong) NSMutableArray *mediaArray;

@property (nonatomic, strong) AVAudioRecorder *myAudioRecorder;
@property (nonatomic, strong) AVAudioPlayer *myAudioPlayer;

@property (nonatomic, strong) NSArray *paths;
@property (nonatomic, strong) NSString *folderPath;



@end



@implementation ListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Library", @"Library");
    
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
        [self.tableView reloadData];
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
    
    [self becomeFirstResponder];
}


- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if(event.type == UIEventSubtypeMotionShake) {
//        NSLog(@"Shake detected...");
        
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
    return _mediaArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *fileNoExtension = [[NSString alloc]init];
    fileNoExtension = [_mediaArray objectAtIndex:indexPath.row];
    
//    NSLog(@"%@ %@", fileNoExtension, myLastFileName);
    
    if ([fileNoExtension isEqualToString:myLastFileName]) {
        cell.textLabel.textColor = [UIColor orangeColor];
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    NSLog(@"Audio selected");
    
    selectedAudio = nil;
    
    if (!_myAudioPlayer.playing) {
        
        selectedAudio = [_mediaArray objectAtIndex:indexPath.row];
        
        [self myPlayButton:nil];
    }
}


-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"did de-select row...");
    
    if (_myAudioPlayer.playing) {
        [self myStopButton:nil];
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
