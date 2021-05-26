//
//  ViewController.m
//  001---NSURLSession
//
//  Created by Cooci on 2018/7/28.
//  Copyright © 2018年 Cooci. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "KCNetwork.h"

@interface ViewController ()<KCDownLoadDelegate>

@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UILabel *lab1;
@property (weak, nonatomic) IBOutlet UILabel *lab2;
@property (weak, nonatomic) IBOutlet UILabel *msgLab;

@property (weak, nonatomic) IBOutlet UILabel *proLab;

@property (nonatomic, strong) KCDownloadNetwork *fileDownloadNetwork;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@" ===== search path ====== %@",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]);
}

- (IBAction)btnClick:(id)sender {
    
//    NSString *url = @"http://127.0.0.1:8080/static/123.mp4";
    NSString *url = @"http://m.lanlingfuli.com/aif/home/getRecomm";
    NSString *token = @"23134543223";
    NSDictionary *para = @{@"agency":@"ios",@"pageIndex":@"1"};

    // NSURLSession  --->  task  --->  id
    // tag  ---  indextify
    
    [[KCNetwork shared] post:url token:token reqData:para handle:^(id result, NSString *msg, NSInteger errorCode) {
        NSLog(@"%@",[NSThread currentThread]);
        if (errorCode == 200) {
            NSLog(@"result == %@",result);
        }else{
            
        }
    }];
    
    
}


//------------------------------大文件下载---------------------------------

// 开始下载
- (IBAction)startDown:(id)sender {
    [self downFile:NO];
}

// 断点续传
- (IBAction)breakpointContinuingly:(id)sender {
    [self downFile:YES];
}


-(void)downFile:(BOOL)breakpoint{
    
    //172.16.127.104
    NSString *fileUrl = @"https://pic.ibaotu.com/00/48/71/79a888piCk9g.mp4";

    
    if(self.fileDownloadNetwork == nil){
        self.fileDownloadNetwork = [KCDownloadNetwork new];
        self.fileDownloadNetwork.tag = 1; // 区别 不同下载任务，状态等信息
        self.fileDownloadNetwork.myDeleate = self;
        //第二个参数 需要重新下载还是接着上次的下载
    }
    
    // 第一次 : 没有文件
    // 断点  :  临时文件
    [self.fileDownloadNetwork downFile:fileUrl isBreakpoint:breakpoint];

}

//暂停下载
- (IBAction)suspendedDown:(id)sender {
    [self.fileDownloadNetwork suspendDownload];
}
//取消下载
- (IBAction)cancelDown:(id)sender {
    [self.fileDownloadNetwork cancelDownload];
}



//进度返回   每一个数据包回来调用一次
- (void)backDownprogress:(float)progress tag:(NSInteger)tag{
//    if (tag == model.tag) { //区别不同的任务
//        model.progress = tag;
//        [self.tableview reloadView];
//    }
    self.progress.progress = progress;
    self.proLab.text = [NSString stringWithFormat:@"%0.1f%@",progress*100,@"%"];
}

//下载成功
- (void)downSucceed:(NSURL*)url tag:(NSInteger)tag{
    NSLog(@"下载成功,准备播放");
    [self paly: url];
    self.progress.progress = 0;
    self.proLab.text = @"0.0%";
    self.fileDownloadNetwork = nil;
}

//下载失败
- (void)downError:(NSError*)error tag:(NSInteger)tag{
    
    self.fileDownloadNetwork = nil;
    self.progress.progress = 0;
    self.proLab.text = @"0.0%";
    NSLog(@"下载失败,请再次下载 :%@",error);
}



//传入本地url 进行视频播放
-(void)paly:(NSURL*)playUrl{
    
    //系统的视频播放器
    AVPlayerViewController *controller = [[AVPlayerViewController alloc]init];
    //播放器的播放类
    AVPlayer * player = [[AVPlayer alloc]initWithURL:playUrl];
    controller.player = player;
    //自动开始播放
    [controller.player play];
    //推出视屏播放器
    [self  presentViewController:controller animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}







@end
