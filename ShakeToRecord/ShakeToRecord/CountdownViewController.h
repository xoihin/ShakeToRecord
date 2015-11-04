//
//  CountdownViewController.h
//  ShakeToRecord
//
//  Created by Xoi's iMac on 2015-10-15.
//  Copyright (c) 2015 XoiAHin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CountdownViewController : UIViewController


@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic, assign) NSInteger secondsCount;

@property (strong, nonatomic) IBOutlet UILabel *countdownLabel;

@property (strong, nonatomic) IBOutlet UILabel *screenWillDim;
@property (strong, nonatomic) IBOutlet UILabel *shakeAgain;



@end
