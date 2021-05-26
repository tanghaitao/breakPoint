//
//  KCFileStreamNetwork.h
//  001---NSURLSession
//
//  Created by Cooci on 2018/7/28.
//  Copyright © 2018年 Cooci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^KCFileHandleBlock)(NSURL* fileUrl, NSString *progress);

@interface KCFileStreamNetwork : NSObject

- (NSURLSessionDataTask*)getDownFileUrl:(NSString*)fileUrl backBlock:(KCFileHandleBlock)handleBlock;
@property(nonatomic,strong)UILabel *proLab;

@end
