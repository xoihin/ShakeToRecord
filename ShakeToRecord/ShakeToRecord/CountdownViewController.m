//
//  CountdownViewController.m
//  ShakeToRecord
//
//  Created by Xoi's iMac on 2015-10-15.
//  Copyright (c) 2015 XoiAHin. All rights reserved.
//

#import "CountdownViewController.h"

@interface CountdownViewController ()

#define kScreenWillDim NSLocalizedString(@"Record starting...", @"Record starting...")
#define kShakeAgain NSLocalizedString(@"Shake again to save recording.", @"Shake again to save recording.")


@end

@implementation CountdownViewController

@synthesize countdownTimer, countdownLabel, secondsCount, screenWillDimLabel, shakeAgain;



- (void)viewDidLoad {
    [super viewDidLoad];
    
    screenWillDimLabel.text = kScreenWillDim;
    shakeAgain.text = kShakeAgain;
    
    [self setTimer];
}


- (void) setTimer {
    secondsCount = 3;
    countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerRun) userInfo:nil repeats:YES];
}


- (void) timerRun {
    
    secondsCount = secondsCount - 1;
    
    NSString *timeOutput = [NSString stringWithFormat:@"%.ld", (long)secondsCount];
    countdownLabel.text = timeOutput;
    
    if (secondsCount == 0) {
        [countdownTimer invalidate];
        countdownTimer = nil;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
