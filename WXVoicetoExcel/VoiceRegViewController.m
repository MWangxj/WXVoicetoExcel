//
//  VoiceRegViewController.m
//  WXVoicetoExcel
//
//  Created by wangxianjin on 16/8/25.
//  Copyright © 2016年 wangxianjin. All rights reserved.
//

#define StateOfReady    0
#define StateOfSpeaking 1
#define StateOfWaiting  2

#import "VoiceRegViewController.h"
#import "WXVoiceSDK.h"
#import "WXSpeechRecognizerView.h"
#import <AVFoundation/AVFoundation.h>
//#import "WXSpeechRecognizerViewDelegate.h"



@interface VoiceRegViewController ()<WXSpeechRecognizerViewDelegate, WXVoiceDelegate>
{
    double _begainTime;
}

@end

@implementation VoiceRegViewController

{
    NSInteger _state;
    NSTimer *_timer;
    NSInteger _waitImageIndex;
    NSInteger _volumn;
    NSInteger _nowVolumn;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGRect frame = [UIScreen mainScreen].bounds;
    //frame.size.height -=64;
    frame.origin.y +=20;

    
    
    _speechRecognizerView = [[WXSpeechRecognizerView alloc] initWithFrame:frame];
    _speechRecognizerView = [[WXSpeechRecognizerView alloc] initWithFrame:frame];
    _speechRecognizerView.delegate = self;
    [self.view addSubview:_speechRecognizerView];
    
    // SDK
    WXVoiceSDK *speechRecognizer = [WXVoiceSDK sharedWXVoice];
    //可选设置
    speechRecognizer.silTime = 1.5f;
    //必选设置
    speechRecognizer.delegate = self;
    
//    [speechRecognizer setAppID:@"838974f93b9b93e7af6369ce1c88f0f224218e6466a17128"];
    //wxd9dbb2f20a952a5d
    [speechRecognizer setAppID:@"wxd9dbb2f20a952a5d"];
    
    [speechRecognizer setDomain:20];
   // [speechRecognizer setMaxResultCount:3];
    [speechRecognizer setResultType:1];//1有标点，0无标点

    
}

#pragma mark -----------WXVoiceDelegate------------

- (void)voiceInputResultArray:(NSArray *)array{
    //一旦此方法被回调，array一定会有一个值，所以else的情况不会发生，但写了会更有安全感的
    if (array && array.count>0) {
        WXVoiceResult *result=[array objectAtIndex:0];
        [_speechRecognizerView setResultText:result.text];
    }else{
        [_speechRecognizerView setResultText:@""];
    }
}
- (void)voiceInputMakeError:(NSInteger)errorCode{
    NSLog(@"%ld",errorCode);
    [_speechRecognizerView setErrorCode:errorCode];
}
- (void)voiceInputVolumn:(float)volumn{
    [_speechRecognizerView setVolumn:volumn];
}
- (void)voiceInputWaitForResult{
    [_speechRecognizerView finishRecorder];
}
- (void)voiceInputDidCancel{
    [_speechRecognizerView didCancel];
}

#pragma mark -----------ViewDelegate------------

- (BOOL)start{
    return [[WXVoiceSDK sharedWXVoice] startOnce];
}
- (void)finishRecorder{
    [[WXVoiceSDK sharedWXVoice] finish];
}
- (void)cancel{
    [[WXVoiceSDK sharedWXVoice] cancel];
}

#pragma mark ====================================

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
