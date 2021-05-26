//
//  KCDownloadNetwork.m
//  001---NSURLSession
//
//  Created by Cooci on 2018/7/28.
//  Copyright © 2018年 Cooci. All rights reserved.
//

#import "KCDownloadNetwork.h"
#import <CommonCrypto/CommonDigest.h>


@interface KCDownloadNetwork()<NSURLSessionDelegate>
@property (nonatomic) BOOL  mIsSuspend;
@property (nonatomic, copy) NSString* fileName;
@property (nonatomic, strong) NSData *myResumeData;

@end

@implementation KCDownloadNetwork

- (void)downFile:(NSString*)fileUrl isBreakpoint:(BOOL)breakpoint{
    
    if (!fileUrl || fileUrl.length == 0 || ![self checkIsUrlAtString:fileUrl]) {
        NSLog(@"fileUrl 无效");
        return ;
    }
    
//    // 判断之前是否存在
//    // 这个地方是不是可以写成唯一的地址
//    if ([[NSFileManager defaultManager] fileExistsAtPath:[self getTmpFileUrl]]) {
//        [self downloadWithResumeData];
//        return;
//    }
    
    NSURL *url = [NSURL URLWithString:fileUrl];

    if (!self.session) {
        
        //0.MD5 加密
        self.fileName = [self md5:fileUrl];
        
        //1.创建NSURLSession,设置代理
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[self currentDateStr]];
        // 允许蜂窝网络: 你可以做偏好设置
        config.allowsCellularAccess = YES;
        config.timeoutIntervalForRequest = 30;
        //创建一个下载线程
        self.session = [NSURLSession sessionWithConfiguration:config
                                                     delegate:self
                                                delegateQueue:[NSOperationQueue mainQueue]];
    }

    //2.创建task 请求句柄
    if(breakpoint == NO){
        self.downloadTask = [self.session downloadTaskWithURL:url];
    }else{
        // 断点续传
        [self downloadWithResumeData];
    }
    
    [self.downloadTask resume];
    
    [self saveTmpFile];
    
}


#pragma mark - NSURLSessionDelegate
//每次传一个包 调用一次该函数 512M
-(void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    // 写下来的/期望的
    float dowProgeress = 1.0 * totalBytesWritten / totalBytesExpectedToWrite;
    if (self.myDeleate && [self.myDeleate respondsToSelector:@selector(backDownprogress:tag:)]) {
        [self.myDeleate backDownprogress:dowProgeress tag:self.tag];
    }
    
}
/*
 2.下载完成之后调用该方法
 */
-(void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location{

    NSLog(@"location == %@",location.path);
    
    //拼接Doc 更换的路径
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) lastObject];
    NSString *file = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",self.fileName]];
    
    //创建文件管理器
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath: file]) {
        //如果文件夹下有同名文件  则将其删除
        [manager removeItemAtPath:file error:nil];
    }
    NSError *saveError;
    [manager moveItemAtURL:location toURL:[NSURL URLWithString:file] error:&saveError];
    
    //将视频资源从原有路径移动到自己指定的路径
    BOOL success = [manager copyItemAtPath:location.path toPath:file error:nil];
    if (success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *url = [[NSURL alloc]initFileURLWithPath:file];
            if(self.myDeleate && [self.myDeleate respondsToSelector:@selector(downSucceed:tag:)])
                [self.myDeleate downSucceed:url tag:self.tag];
        });
    }
    //已经拷贝 删除缓存文件
    [manager removeItemAtPath:location.path error:nil];
    
    [manager removeItemAtPath:[self getTmpFileUrl] error:nil];
}

//下载失败调用
-(void)URLSession:(nonnull NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    
    if(error && self.myDeleate && [self.myDeleate respondsToSelector:@selector(downError:tag:)] && error.code != -999)
        [self.myDeleate downError:error tag:self.tag];
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session{
    NSLog(@"所有后台任务已经完成: %@",session.configuration.identifier);
    
}
    


#pragma mark - private

//暂停下载
-(void)suspendDownload{
 
    if (self.mIsSuspend) {
        [self.downloadTask resume];
    }else{
        [self.downloadTask suspend];
    }
    self.mIsSuspend = !self.mIsSuspend;
}


//取消下载
-(void)cancelDownload{
    
//    [self.downloadTask cancel];
    __weak typeof(self) weakSelf = self;
    //已经下载好的数据
    [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
       //假如不做内存处理，断点续传时从磁盘读取写入的临时文件开始任务下载
//        weakSelf.resumeData = resumeData;
        weakSelf.downloadTask  = nil;
        [resumeData writeToFile:[weakSelf getTmpFileUrl] atomically:NO];
    }];
    
    
}

//断点下载
-(void)downloadWithResumeData{

    if (!self.session) {
        return;
    }
    
    NSData *data = nil;
    
    if (self.resumeData) {
        data = self.resumeData;
    }else{
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSData *datas     = [fm contentsAtPath:[self getTmpFileUrl]];
        NSString *fileStr = [[NSString alloc] initWithData:datas encoding:NSUTF8StringEncoding];

        NSLog(@"%@----%@",[self getTmpFileUrl],fileStr);
        data = datas;
    }
    
    self.downloadTask = [self.session downloadTaskWithResumeData:data];
}

//未下载完的临时文件url地址
-(NSString*)getTmpFileUrl{
    
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [docPath stringByAppendingPathComponent:@"download.tmp"];
    NSLog(@"%@",filePath);
    
//    NSString* url = [NSString stringWithFormat:@"/Users/LM/Desktop/%@.tmp",self.fileName];
    return filePath;
}

//提前保存临时文件 预防下载中杀掉app
//开启定时器
-(void)saveTmpFile{
    
    [NSTimer scheduledTimerWithTimeInterval:4 repeats:YES block:^(NSTimer * _Nonnull timer) {
       
        [self downloadTmpFile];
    }];

}

//杀掉app后 不至于下载的部分文件全部丢失
- (void)downloadTmpFile{
    __weak typeof(self) weakSelf = self;
    [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        
        weakSelf.resumeData = resumeData;
        weakSelf.downloadTask  = nil;
        [resumeData writeToFile:[weakSelf getTmpFileUrl] atomically:NO];
        
        self.downloadTask =  [self.session downloadTaskWithResumeData:resumeData];
        [self.downloadTask resume];
    }];

    
}

//用url获取文件名称 MD5加密
- (NSString *)md5:(NSString *)string{
    const char *cStr = [string UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02X", digest[i]];
    }
    
    return result;
}

//获取当前时间 下载id标识用
- (NSString *)currentDateStr{
    NSDate *currentDate = [NSDate date];//获取当前时间，日期
    NSTimeInterval timeInterval = [currentDate timeIntervalSince1970];
    return [NSString stringWithFormat:@"%.f",timeInterval];
}

- (BOOL)checkIsUrlAtString:(NSString *)url {
    NSString *pattern = @"http(s)?://([\\w-]+\\.)+[\\w-]+(/[\\w- ./?%&=]*)?";
    
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:nil];
    NSArray *regexArray = [regex matchesInString:url options:0 range:NSMakeRange(0, url.length)];
    
    if (regexArray.count > 0) {
        return YES;
    }else {
        return NO;
    }
}

- (void)dealloc
{
    [self.session invalidateAndCancel];
    self.session = nil;
    [self.downloadTask cancel];
    self.downloadTask = nil;
}



@end
