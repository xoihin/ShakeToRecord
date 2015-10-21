//
//  ShakeToRecordTableViewController.h
//  ShakeToRecord
//
//  Created by Xoi's iMac on 2015-10-13.
//  Copyright (c) 2015 XoiAHin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ListTableViewController : UITableViewController


@property (strong, nonatomic) IBOutlet UIBarButtonItem *playButtonOutlet;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *pauseButtonOutlet;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *stopButtonOutlet;

@property (strong, nonatomic) NSTimer *myAudioTimer;
@property (strong, nonatomic) IBOutlet UISlider *positionSlider;

- (IBAction)changePosition:(UISlider *)sender;


- (IBAction)myPlayButton:(UIBarButtonItem *)sender;
- (IBAction)myPauseButton:(UIBarButtonItem *)sender;
- (IBAction)myStopButton:(UIBarButtonItem *)sender;




@end
