//
//  WXVoiceSDK.h
//  WXVoiceSDK
//
//  Copyright (c) 2013年 Tencent Research. All rights reserved.
//

#import <Foundation/Foundation.h>


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

//语音识别
#define WXVoiceRecoErrorOfNoSound           -301    //没有说话(或音量过小)
#define WXVoiceRecoErrorOfVoiceTooLarge     -302    //语音过长
#define WXVoiceRecoErrorOfRecord            -303    //录音出错
#define WXVoiceRecoErrorOfCannotUseMic      -304    //麦克风被禁用
/*其它错误
 //网络错误
 [-104,-100]网络底层错误
 [1,1000]系统错误码（通常也是由网络问题引起的）及[201, 505]HTTP错误码
 
 //服务错误
 [1000,++]服务器错误，
 */

//下面是兼容之前版本的错误码名称，
#define WXVoiceErrorOfSuccess       0       //没错误0
#define WXVoiceErrorOfNoNetWork     -201    //没有网络
#define WXVoiceErrorOfTimeOut       -202    //网络超时错误
#define WXVoiceErrorOfQuotaExhaust  -203    //配额用完
#define WXVoiceErrorOfAppIDError    -204    //AppId 不存在或失效
#define WXVoiceErrorOfNoSound       -301    //没有说话(或音量过小)
#define WXVoiceErrorOfVoiceTooLarge -302    //语音过长
#define WXVoiceErrorOfRecord        -303    //录音出错
#define WXVoiceErrorOfCannotUseMic  -304    //麦克风被禁用
//=============================================================

typedef enum {
    GrammarTypeOfABNF = 0,
    GrammarTypeOfWordlist = 1,
}WXGrammarType;

//--返回结果的元素类型（返回结果是由此类型组成的NSArray）------
@interface WXVoiceResult : NSObject
@property (nonatomic,copy)NSString *text;       //语音识别结果的文本内容
@end

//--代理的回调方法----------------------------------------

@protocol WXVoiceDelegate <NSObject>

- (void)voiceInputResultArray:(NSArray *)array;   //识别成功，返回结果，元素类型为WXVoiceResult，现阶段数组内只有一个元素
- (void)voiceInputMakeError:(NSInteger)errorCode;   //出现错误，错误码请参见官方网站

- (void)voiceInputWaitForResult;   //录音完成，等待服务器返回识别结果。此时不会再接受新的语音

- (void)voiceInputDidCancel;   //在手动调用的cancel后，取消完成时回调

@optional

- (void)voiceInputVolumn:(float)volumn;         //音量，界限为0-30，通常音量范围在0-15之间

@end



//--语音识别单例----------------------------------------


@interface WXVoiceSDK : NSObject

@property (nonatomic,assign)id<WXVoiceDelegate>delegate;

@property (nonatomic,assign)float silTime;  //静音检查时间，开始录音，并检测到有语音产生后，超过此时间没有声音，则自动完成本次录音，默认1.5（秒）

@property (nonatomic,assign)int domain;

+ (WXVoiceSDK *)sharedWXVoice;          //获取单例对象

+ (void)releaseWXVoice;                 //释放单例对象及其资源

- (void)setAppID:(NSString *)appid; //设置微信公众平台appid，此处有可能会联网检查认证

- (BOOL)startOnce;      //开始一次识别（返回值为是否成功)
- (BOOL)startOnceWithGrammarString:(NSString *)words andType:(WXGrammarType)type;   //使用语法或词表进行语音识别。

- (void)finish;      //结束本次录音，等待识别结果

- (void)cancel;     //取消本次识别，需要等待回调后才能开始下一次

- (void)setResultType:(NSInteger)type;  // 设置识别类型，0无标点，1有标点，默认值0
@end
