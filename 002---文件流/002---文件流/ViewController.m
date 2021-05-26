//
//  ViewController.m
//  002---文件流
//
//  Created by Cooci on 2018/7/31.
//  Copyright © 2018年 Cooci. All rights reserved.
//

#import "ViewController.h"
#import "KCFileStreamNetwork.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


//文件流下载
- (IBAction)fileSteamBtn:(id)sender {
    
    __weak typeof(self) weakSelf = self;
    
    KCFileStreamNetwork *fileStream = [KCFileStreamNetwork new];
    [fileStream  getDownFileUrl:@"https://pic.ibaotu.com/00/48/71/79a888piCk9g.mp4" backBlock:^(NSURL *fileUrl,NSString *progress) {
        weakSelf.progressLabel.text = progress;
        if (fileUrl) {
            NSLog(@"文件路径:%@",[fileUrl absoluteString]);
        }
    }];
    
}

- (IBAction)editFileBtn:(id)sender {
    
    NSString* filePath =  @"/Users/LM/Desktop/data.txt";
    NSFileManager* fm = [NSFileManager defaultManager];
    NSData* fileData =  [fm contentsAtPath:filePath];
    
    NSFileHandle *fielHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    //[fielHandle seekToFileOffset:2];
    [fielHandle seekToEndOfFile];
    NSString *str = @"你好";
    NSData* stringData = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    [fielHandle writeData:stringData];
    [fielHandle closeFile];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
