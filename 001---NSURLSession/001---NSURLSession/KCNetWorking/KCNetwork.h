//
//  KCNetwork.h
//  001---NSURLSession
//
//  Created by Cooci on 2018/7/28.
//  Copyright © 2018年 Cooci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCDownloadNetwork.h"
//#import "KCFileStreamNetwork.h"

typedef void (^KCRequestHandleBlock)(id result,NSString* msg, NSInteger errorCode);

@interface KCNetwork : NSObject

+ (instancetype)shared;

- (NSURLSessionDataTask *)post:(NSString*)url token:(NSString*)token reqData:(NSDictionary*)params handle:(KCRequestHandleBlock)handleblock;

@end
