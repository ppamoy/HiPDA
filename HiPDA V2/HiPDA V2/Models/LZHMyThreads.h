//
//  LZHMyThreads.h
//  HiPDA V2
//
//  Created by leizh007 on 15/5/27.
//  Copyright (c) 2015年 leizh007. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LZHNetworkFetcher.h"

@interface LZHMyThreads : NSObject

@property (copy ,nonatomic) NSString *tid;
@property (copy ,nonatomic) NSString *title;
@property (copy ,nonatomic) NSString *fidName;

+(void)getMyThreadsInPage:(NSInteger)page completionHandler:(LZHNetworkFetcherCompletionHandler)completion;

@end