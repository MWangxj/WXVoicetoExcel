//
//  WXSpeechRecognizerView.m
//  WXVoiceSDKDemo
//
//  Created by 宫亚东 on 13-12-26.
//  Copyright (c) 2013年 Tencent Research. All rights reserved.
//

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
    [_button setImage:[UIImage imageNamed:@"voice011.png"] forState:UIControlStateNormal];
    
    _reSetButton.enabled = NO;
    [_reSetButton setImage:[UIImage imageNamed:@"reset001.png"] forState:UIControlStateNormal];
        [self setText:text];
    NSLog(@"*************|%@|*************",text);
    _resultTF.text=text;
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
        [self setResultText:[NSString stringWithFormat:@"ErrorCode = %d", errorCode]];
    } else {
        [self setResultText:[NSString stringWithFormat:@"ErrorCode = %d\n点击重新开始", errorCode]];
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
        _resultTF.textAlignment=NSTextAlignmentCenter;
        [cell.contentView addSubview:_resultTF];
        
        
        _testBTN=[UIButton buttonWithType:UIButtonTypeCustom];
        _testBTN.frame=CGRectMake(cell.frame.size.width/5*4, 0, cell.frame.size.width/6.82, cell.frame.size.height);
        //testBTN.backgroundColor=[UIColor blueColor];
        [_testBTN setImage:[UIImage imageNamed:@"voice011.png"] forState:UIControlStateNormal];
        [_testBTN addTarget:self action:@selector(clickedButton:) forControlEvents:UIControlEventTouchUpInside];
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

- (void) resultStringtoDigit:(NSString *)text{
    NSArray *resultArry=[NSArray arrayWithObjects:@"零",@"一",@"二",@"三",@"四",@"五",@"六",@"七",@"八",@"九",@"十",@"百",@"千",@"万", nil];
    NSLog(@"*******************************");
    NSLog(@"%ld",text.length);
    
    for (int i=0; i<text.length-1; i++) {
        unichar temp=[text characterAtIndex:i];
        for (NSString *str in resultArry) {
            if(temp==[str characterAtIndex:0]){
                NSLog(@"转化为数字是:－－－－－%lu－－－－/r/n",(unsigned long)[resultArry indexOfObject:str]);
            }
            else{
                NSLog(@"你说的可能不是数字。");
            }
        }
    }
    
    
}

@end
