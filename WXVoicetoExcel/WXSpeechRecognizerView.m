//
//  WXSpeechRecognizerView.m
//  WXVoiceSDKDemo
//
//  Created by 宫亚东 on 13-12-26.
//  Copyright (c) 2013年 Tencent Research. All rights reserved.
//
#define TAGOFFSET       100

#define StateOfReady    0
#define StateOfSpeaking 1
#define StateOfWaiting  2

#define CONNECTION_HOST "localhost"
#define CONNECTION_USER "root"
#define CONNECTION_PASS "123456"
#define CONNECTION_DB   "sys"

#define SERVICEIP @"192.168.2.102"
#define SERVICEPORT 55555

#import "WXSpeechRecognizerView.h"
#include "mysql.h"
#include "GCDAsyncSocket.h"

@interface WXSpeechRecognizerView()<GCDAsyncSocketDelegate>

@property (nonatomic) MYSQL *connection;

@end

@implementation WXSpeechRecognizerView
{
    NSMutableDictionary * _resultToSocketServer;
    NSInteger _tfIndex;
    NSInteger _state;
    NSTimer *_timer;
    NSInteger _waitImageIndex;
    NSInteger _volumn;
    NSInteger _nowVolumn;
    GCDAsyncSocket *socket;
    
    

}
@synthesize delegate = _delegate;
@synthesize resultFrame = _resultFrame;
@synthesize resultAlignment = _resultAlignment;


- (void)removeFromSuperview{
    [_timer invalidate];
    _timer = nil;
    [super removeFromSuperview];
}

/**
 *  设置音量
 *
 *  @param volumn 音量
 */

- (void)setVolumn:(float)volumn{
    //3-11
    if (_state == StateOfSpeaking) {
        if (volumn *3+3>_volumn) {
            _volumn = volumn *3+3;
        }
        
        if (_volumn>11) {
            _volumn = 11;
        }

    }
}

/**
 *  完成录音
 */

- (void)finishRecorder{
    _state = StateOfWaiting;
    if (_timer) {
        [_timer invalidate];
    }
    [self setText:@"识别中..."];
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timeUp) userInfo:nil repeats:YES];
}

/**
 *  计时器
 */

- (void)timeUp{
    if (_state == StateOfSpeaking) {
        if (_volumn == 3 && _nowVolumn <5) {
            static int t = 4;
            t--;
            if (t == 0) {
                _nowVolumn = 7- _nowVolumn;
                t = 10;
            }
        } else {
            if (_volumn>_nowVolumn) {
                _nowVolumn+=1;
            } else if (_volumn<_nowVolumn) {
                _nowVolumn-=1;
            } else{
                _volumn = 3;
            }
        }
        NSString *imageName = [NSString stringWithFormat:@"voice%03d.png", _nowVolumn];
        [_button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        
    } else if (_state == StateOfWaiting) {
        //wait 001-007
        _waitImageIndex = _waitImageIndex%7 + 1;
        [_button setImage:[UIImage imageNamed:[NSString stringWithFormat:@"voice_wait%03d.png", _waitImageIndex]] forState:UIControlStateNormal];
    }
}

/**
 *  添加结果试图
 *
 *  @param text 结果
 */

- (void)setText:(NSString *)text{

    [_textView removeFromSuperview];
//    [_textView release];
    
    _textView = [[UITextView alloc] initWithFrame:self.resultFrame];
    _textView.backgroundColor = [UIColor clearColor];
    _textView.textColor = [UIColor whiteColor];
    _textView.font = [UIFont systemFontOfSize:20];
    _textView.editable = NO;
    _textView.userInteractionEnabled = NO;
    _textView.text = text;
    _textView.textAlignment = self.resultAlignment;
   
    [self addSubview:_textView];
}

/**
 *  设置结果
 *
 *  @param text 结果
 */

- (void)setResultText:(NSString *)text{
    _state = StateOfReady;
    [_timer invalidate];
    _timer = nil;
//    [_button setImage:[UIImage imageNamed:@"voice011.png"] forState:UIControlStateNormal];
//    
//    _reSetButton.enabled = NO;
//    [_reSetButton setImage:[UIImage imageNamed:@"reset001.png"] forState:UIControlStateNormal];
        //[self setText:text];
    NSLog(@"*************|%@|*************",text);
    UITextField *tf=[self viewWithTag:_tfIndex];
    NSString *resultText=[text substringWithRange:NSMakeRange(0, text.length-1)];
    
    double resultValue=[resultText doubleValue];
    if (resultValue>0) {
        tf.text=[NSString stringWithFormat:@"%lg",resultValue];
    }else{
        NSString* result= [self arabicNumberalsFromChineseNumberals:[text substringWithRange:NSMakeRange(0, text.length-1)]];
        NSLog(@"*************|%@|*************",result);
        
        tf.text=result;
    }
}

/**
 *  设置错误代码
 *
 *  @param errorCode 错误代码
 */
- (void)setErrorCode:(NSInteger)errorCode{
    _state = StateOfReady;
    [_timer invalidate];
    _timer = nil;
    [_button setImage:[UIImage imageNamed:@"voice011.png"] forState:UIControlStateNormal];
    
    _reSetButton.enabled = NO;
    [_reSetButton setImage:[UIImage imageNamed:@"reset001.png"] forState:UIControlStateNormal];
    if (self.resultAlignment == NSTextAlignmentLeft) {
        [self setResultText:[NSString stringWithFormat:@"ErrorCode = %zi", errorCode]];
    } else {
        [self setResultText:[NSString stringWithFormat:@"ErrorCode = /%zi\n点击重新开始", errorCode]];
    }
}

/**
 *  取消录制
 */

- (void)didCancel{
    _state = StateOfReady;
    [_timer invalidate];
    _timer = nil;
    _reSetButton.enabled = NO;
    [_reSetButton setImage:[UIImage imageNamed:@"reset001.png"] forState:UIControlStateNormal];
    _button.enabled = YES;
    [_button setImage:[UIImage imageNamed:@"voice011.png"] forState:UIControlStateNormal];
    if (self.resultAlignment == NSTextAlignmentLeft) {
        [self setText:@"已取消"];;
    } else {
        [self setText:@"已取消\n点击重新开始"];
    }
    
}

/**
 *  初始化视图
 *
 *  @param frame 边框
 *
 *  @return 视图
 */
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _state = StateOfReady;
        _resultToSocketServer=[[NSDictionary alloc]init];
        
        /*
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.connection = mysql_init(NULL);
            MYSQL *connection = mysql_real_connect(self.connection, CONNECTION_HOST, CONNECTION_USER, CONNECTION_PASS, CONNECTION_DB, 3306, NULL, 0);
            
            if (connection) {
               //连接上之后要做的事情
                
            } else {
                NSLog(@"fail to connect DB");
            }
        });
        
        socket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        //socket.delegate = self;
        NSError *err = nil;
        if(![socket connectToHost:SERVICEIP onPort:SERVICEPORT error:&err])
        {
            NSLog(@"*****%@*******",err.description);
        }else
        {
            NSLog(@"ok");
        }
*/
        
//        UIImageView *iv = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"bg_320x568.png"]];
////        iv.frame = CGRectMake(0, 0, 320, 568);
//        //iv.frame = CGRectMake(0, 0, 400, 600);
//        iv.frame = CGRectMake(0,0, frame.size.width, frame.size.height);
//        [self addSubview:iv];
//        [iv release];
        
//        self.resultFrame = CGRectMake(10, 120, 300, 80);
//        self.resultAlignment = NSTextAlignmentCenter;
//        [self setText:@"点击开始说话"];
        _dataTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _dataTable.dataSource=self;
        _dataTable.delegate=self;
        [self addSubview:_dataTable];
        
        /*
        UILabel *resultLabel=[[UILabel alloc]initWithFrame:CGRectMake(1, 1, frame.size.width/5, frame.size.height/12.13)];
        resultLabel.text=@"结果:";
        resultLabel.textColor=[UIColor redColor];
        resultLabel.textAlignment=NSTextAlignmentRight;
        [self addSubview:resultLabel];
        
         _resultTF=[[UITextField alloc]initWithFrame:CGRectMake(frame.size.width/5, 1, frame.size.width/5*3, frame.size.height/12.13)];
        _resultTF.enabled=false;
        _resultTF.textAlignment=NSTextAlignmentCenter;
        [self addSubview:_resultTF];
        
        
        _testBTN=[UIButton buttonWithType:UIButtonTypeCustom];
        _testBTN.frame=CGRectMake(frame.size.width/5*4, 1, frame.size.width/6.82, frame.size.height/12.13);
        //testBTN.backgroundColor=[UIColor blueColor];
        [_testBTN setImage:[UIImage imageNamed:@"voice011.png"] forState:UIControlStateNormal];
        [_testBTN addTarget:self action:@selector(clickedButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_testBTN];
        */
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.frame = CGRectMake(105, frame.size.height-220, 110, 110);
        [_button setImage:[UIImage imageNamed:@"voice011.png"] forState:UIControlStateNormal];
        [_button addTarget:self action:@selector(clickedButton:) forControlEvents:UIControlEventTouchUpInside];
        //[self addSubview:_button];
        
        
        _reSetButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _reSetButton.frame = CGRectMake(225, frame.size.height-220+55, 55, 55);
        _reSetButton.enabled = NO;
        [_reSetButton setImage:[UIImage imageNamed:@"reset001.png"] forState:UIControlStateNormal];
        [_reSetButton addTarget:self action:@selector(clickedButton:) forControlEvents:UIControlEventTouchUpInside];
        //[self addSubview:_reSetButton];
    }
    return self;
}

#pragma **********tableViewdalegate*************
/**
 *  每个section中有多少行cell
 *
 *  @param tableView <#tableView description#>
 *  @param section   <#section description#>
 *
 *  @return <#return value description#>
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{

    return 10;

}

/**
 *  绘制cell
 *
 *  @param tableView 所在的tableview
 *  @param indexPath 第几个cell
 *
 *  @return cell
 */

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"cell";
    
    UITableViewCell  *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell  alloc]initWithStyle:UITableViewCellStyleDefault   reuseIdentifier:identifier];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width/5, cell.frame.size.height)];
        label.text=@"结果:";
        label.textAlignment=NSTextAlignmentCenter;
        [cell.contentView addSubview:label];
        
        _resultTF=[[UITextField alloc]initWithFrame:CGRectMake(cell.frame.size.width/5, 0, cell.frame.size.width/5*3, cell.frame.size.height)];
        _resultTF.enabled=false;
        _resultTF.tag=indexPath.row+TAGOFFSET;
        _resultTF.textAlignment=NSTextAlignmentCenter;
        [cell.contentView addSubview:_resultTF];
        
        
        _testBTN=[UIButton buttonWithType:UIButtonTypeCustom];
        _testBTN.frame=CGRectMake(cell.frame.size.width/5*4, 0, cell.frame.size.width/6.82, cell.frame.size.height);
        //testBTN.backgroundColor=[UIColor blueColor];
        [_testBTN setImage:[UIImage imageNamed:@"voice011.png"] forState:UIControlStateNormal];
        [_testBTN addTarget:self action:@selector(clickedButton:) forControlEvents:UIControlEventTouchUpInside];
        _testBTN.tag=indexPath.row+TAGOFFSET;
        [cell.contentView addSubview:_testBTN];
        
    }
    //UILabel *label3 = (UILabel *)[cell.contentView viewWithTag:1];
    //label1.text = @"44444";
    
    return cell;
}

#pragma *********GCDAsyncSocketDelehate**********

/**
 *  socket连接
 *
 *  @param sock socket对象
 *  @param host 主机
 *  @param port 端口
 */

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{

    
}



- (void)clickedButton:(UIButton *)btn{
    _tfIndex=btn.tag;
    if (btn == _reSetButton) {
        if (_state != StateOfReady) {
            _reSetButton.enabled = NO;
            [_reSetButton setImage:[UIImage imageNamed:@"reset001.png"] forState:UIControlStateNormal];
            _button.enabled = NO;
            [_button setImage:[UIImage imageNamed:@"voice001.png"] forState:UIControlStateNormal];
            if (_timer) {
                [_timer invalidate];
                _timer = nil;
            }
            [self setText:@"正在取消..."];
            [_delegate cancel];
        }
        return;
    }
    if (_state == StateOfReady) {
        if ([_delegate start]) {
            _state = StateOfSpeaking;
            _nowVolumn = 3;
            _volumn = 3;
            _reSetButton.enabled = YES;
            [_reSetButton setImage:[UIImage imageNamed:@"reset002.png"] forState:UIControlStateNormal];
            [self setText:@"语音已开启，请说话..."];
            if (_timer) {
                [_timer invalidate];
            }
            _timer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(timeUp) userInfo:nil repeats:YES];
        }
    } else if (_state == StateOfSpeaking) {
        [_delegate finishRecorder];
    }
    
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

/**
 *  中文字符串转数字
 *
 *  @param text <#text description#>
 */

- (NSString *)arabicNumberalsFromChineseNumberals:(NSString *)arabic{
    NSMutableDictionary * mdic =[[NSMutableDictionary alloc]init];
    
    [mdic setObject:[NSNumber numberWithInt:10000] forKey:@"万"];
    [mdic setObject:[NSNumber numberWithInt:1000] forKey:@"千"];
    [mdic setObject:[NSNumber numberWithInt:100] forKey:@"百"];
    [mdic setObject:[NSNumber numberWithInt:10] forKey:@"十"];
    
    [mdic setObject:[NSNumber numberWithInt:9] forKey:@"九"];
    [mdic setObject:[NSNumber numberWithInt:8] forKey:@"八"];
    [mdic setObject:[NSNumber numberWithInt:7] forKey:@"七"];
    [mdic setObject:[NSNumber numberWithInt:6] forKey:@"六"];
    [mdic setObject:[NSNumber numberWithInt:5] forKey:@"五"];
    [mdic setObject:[NSNumber numberWithInt:4] forKey:@"四"];
    [mdic setObject:[NSNumber numberWithInt:3] forKey:@"三"];
    [mdic setObject:[NSNumber numberWithInt:2] forKey:@"二"];
    [mdic setObject:[NSNumber numberWithInt:2] forKey:@"两"];
    [mdic setObject:[NSNumber numberWithInt:1] forKey:@"一"];
    [mdic setObject:[NSNumber numberWithInt:0] forKey:@"零"];
    
    //    NSLog(@"%@",mdic);
    
    BOOL flag=YES;//yes表示正数，no表示负数
    NSString * s=[arabic substringWithRange:NSMakeRange(0, 1)];
    NSRange d=[arabic rangeOfString:@"点"];
    if (d.length>0) {
        NSMutableString *point=[[NSMutableString alloc]initWithString:@"."];
        if([s isEqualToString:@"负"]){
            flag=NO;
        }
        int i=0;
        if(!flag){
            i=1;
        }
        int sum=0;//和
        int num[20];//保存单个汉字信息数组
        for(int i=0;i<20;i++){//将其全部赋值为0
            num[i]=0;
        }
        int k=0;//用来记录数据的个数
        
        //如果是负数，正常的数据从第二个汉字开始，否则从第一个开始
        for(;i<d.location;i++){
            NSString * key=[arabic substringWithRange:NSMakeRange(i, 1)];
            int tmp=[[mdic valueForKey:key] intValue];
            num[k++]=tmp;
        }
        
        for(int j=d.location+1;j<[arabic length];j++){
            NSString * key=[arabic substringWithRange:NSMakeRange(j, 1)];
            int tmp=[[mdic valueForKey:key] intValue];
            num[j]=tmp;
        }
        
        for (int j=d.location+1; j<[arabic length]; j++) {
            [point appendString:[NSString stringWithFormat:@"%d",num[j]]];
            
        }
        //将获得的所有数据进行拼装
        for(int i=0;i<k;i++){
            if(num[i]<10&&num[i+1]>=10){
                sum+=num[i]*num[i+1];
                i++;
            }else{
                sum+=num[i];
            }
        }
        NSMutableString * result=[[NSMutableString alloc]init];;
        if(flag){//如果正数
            NSLog(@"%d%@",sum,point);
            result=[NSMutableString stringWithFormat:@"%d%@",sum,point];
        }else{//如果负数
            NSLog(@"-%d",sum);
            result=[NSMutableString stringWithFormat:@"-%d%@",sum,point];
        }
        return result;

    }else{
        if([s isEqualToString:@"负"]){
            flag=NO;
        }
        int i=0;
        if(!flag){
            i=1;
        }
        int sum=0;//和
        int num[20];//保存单个汉字信息数组
        for(int i=0;i<20;i++){//将其全部赋值为0
            num[i]=0;
        }
        int k=0;//用来记录数据的个数
        
        //如果是负数，正常的数据从第二个汉字开始，否则从第一个开始
        for(;i<[arabic length];i++){
            NSString * key=[arabic substringWithRange:NSMakeRange(i, 1)];
            int tmp=[[mdic valueForKey:key] intValue];
            num[k++]=tmp;
        }
        //将获得的所有数据进行拼装
        for(int i=0;i<k;i++){
            if(num[i]<10&&num[i+1]>=10){
                sum+=num[i]*num[i+1];
                i++;
            }else{
                sum+=num[i];
            }
        }
        NSMutableString * result=[[NSMutableString alloc]init];;
        if(flag){//如果正数
            NSLog(@"%d",sum);
            result=[NSMutableString stringWithFormat:@"%d",sum];
        }else{//如果负数
            NSLog(@"-%d",sum);
            result=[NSMutableString stringWithFormat:@"-%d",sum];
        }
        return result;
    }
    }
@end
