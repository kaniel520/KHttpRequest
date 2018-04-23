//
//  KHttpRequest.h
//  GlassesDoc
//
//  Created by kaniel_mac on 8/15/15.
//  Copyright (c) 2015 kaniel. All rights reserved.
//

#import <Foundation/Foundation.h>


#define KHTTP_REQUSET [KHttpRequest khttpRequest]

@interface KHttpRequest : NSObject

// 获取实例
+ (KHttpRequest *)khttpRequest;
// 下载对应数据 get请求
- (NSData*)requestDataSync:(NSString *)path;

// 下载对应数据 post请求
- (NSData*)requestDataWithPostSync:(NSString *)path;
// post请求
- (NSData *)postDataSync:(NSString *)path withDic:(NSDictionary *)dicNeedPost;

// post请求
- (NSData *)postFormDataSync:(NSString *)path withDic:(NSDictionary *)dicNeedPost;

// 测试post
- (NSData *)testPost:(NSString *)path;

- (void)addHeaders:(NSDictionary *)dic;

// put
- (BOOL)putDataSync:(NSString *)path withData:(NSData *)data;

@end
