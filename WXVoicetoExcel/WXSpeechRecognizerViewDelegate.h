//
//  WXSpeechRecognizerViewDelegate.h
//  WXVoicetoExcel
//
//  Created by wangxianjin on 16/8/25.
//  Copyright © 2016年 wangxianjin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WXSpeechRecognizerViewDelegate <NSObject>

- (BOOL)start;
- (void)finishRecorder;
- (void)cancel;

@end
