//
//  WXSpeechSynthesizer.h
//  WXVoiceSDK
//
//  Created by 宫亚东 on 13-12-24.
//  Copyright (c) 2013年 Tencent Research. All rights reserved.
//

//--------------------------------错误码------------------------
//公用
#ifndef __WX_Error_Code_Base__
#define __WX_Error_Code_Base__

#define WXErrorOfSuccess            0       //没错误0
#define WXErrorOfNoNetWork          -201    //没有网络
#define WXErrorOfTimeOut            -202    //网络超时错误
#define WXErrorOfQuotaExhaust       -203    //配额用完
#define WXErrorOfAppIDError         -204    //AppId 不存在或失效
#define WXErrorOfTextNull           -402    //文本为空（在语音识别中指的是，Grammar文本）
#define WXErrorOfTextOverlength     -403    //文本过长

#endif

//语音合成
#define WXTTSErrorOfBreak           -401    //断点续传
#define WXTTSErrorOfTextNull        -402    //文本为空
#define WXTTSErrorOfTextOverlength  -403    //文本长度超过限制
/*其它错误
 //网络错误
 [-104,-100]网络底层错误
 [1,1000]系统错误码（通常也是由网络问题引起的）及[201, 505]HTTP错误码
 
 //服务错误
 [1000,++]服务器错误，
 */


//=============================================================


//----合成语音的格式
#define SpeechFormatOfMP3 0     //MP3，推荐使用的格式
#define SpeechFormatOfWAV 1     //WAV，体积比较大
#define SpeechFormatOfAMR 2     //AMR，苹果不能直接播放的格式


@protocol WXSpeechSynthesizerDelegate <NSObject>
//在合成成功结束后，回调合成的语音数据及其格式
- (void)speechSynthesizerResultSpeechData:(NSData *)speechData speechFormat:(int)speechFormat;
//错误码请参见官方网站
- (void)speechSynthesizerMakeError:(NSInteger)error;
//在手动调用的cancel，并完成取消后的回调
- (void)speechSynthesizerDidCancel;

@end

#import <Foundation/Foundation.h>

@interface WXSpeechSynthesizer : NSObject

@property (nonatomic,assign)id<WXSpeechSynthesizerDelegate>delegate;

+ (WXSpeechSynthesizer *)sharedSpeechSynthesizer;   //获取单例
+ (void)releaseSpeechSynthesizer;                   //释放使用的资源及单例对象

- (void)setAppID:(NSString *)appid; //设置微信公众平台appid，此处有可能会联网检查认证
- (void)setSpeechFormat:(int)speechFormat;      //设置合成语音的格式。默认为0，MP3格式，不建议修改
- (void)setVolumn:(float)volumn;    //音量范围0-2

- (BOOL)startWithText:(NSString *)text;     //开始进行语音合成
- (void)cancel;                             //取消本次合成

@end
