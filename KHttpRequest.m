//
//  KHttpRequest.m
//  GlassesDoc
//
//  Created by kaniel_mac on 8/15/15.
//  Copyright (c) 2015 kaniel. All rights reserved.
//

#import "KHttpRequest.h"
#import "NSDictionary+MKNKAdditions.h"

#define REQUEST_TIMEOUT 60// 超时

@interface KHttpRequest()<NSURLConnectionDataDelegate, NSURLConnectionDelegate>
{
    NSURLConnection *m_connet;
//    NSURLSession *m_connect;
    NSMutableData *m_recvData;
    BOOL m_isFinished;// 完整接收
    BOOL m_isError;// 是否出错
    NSMutableURLRequest *m_request;
    NSMutableDictionary *m_dicHeaders;
    NSInteger m_statusCode;
}

@end

@implementation KHttpRequest


- (id)init
{
    if (self = [super init]) {
        m_recvData = [[NSMutableData alloc]init];
    }
    return self;
}

+ (KHttpRequest *)khttpRequest
{
    KHttpRequest *re = [[KHttpRequest alloc]init];
    
    return re;
}

/**
 * 设置POST以Form表单方式请求
 **/
+ (void)setFormDataRequest:(NSMutableURLRequest *)request fromData:(NSDictionary *)formdata{
    
    NSString *boundary = @"kanielBoundary";
    
    //设置请求体中内容
    NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    [request setValue:
     [NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset]
          forHTTPHeaderField:@"Content-Type"];
    NSString * bodyStringFromParameters = [formdata urlEncodedKeyValueString];
    

    [request setHTTPBody:[bodyStringFromParameters dataUsingEncoding:NSUTF8StringEncoding]];
    
}




#pragma mark url connection delegate
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    m_isError = YES;
    DLog(@"请求连接失败:%@", error);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    //DLog(@"收到响应");
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    m_statusCode = httpResponse.statusCode;
    [m_recvData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //NSLog(@"收到数据:%lu", (unsigned long)data.length);
    
    [m_recvData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //DLog(@"url:%@,结束接收数据:%f KB", m_request.URL, (unsigned long)m_recvData.length / 1024.0);
    m_isFinished = YES;
    
}

- (void)addHeaders:(NSDictionary *)dic{
    
    if (!m_dicHeaders) {
        m_dicHeaders = [[NSMutableDictionary alloc]init];
    }
    [m_dicHeaders addEntriesFromDictionary:dic];
}

- (void)setShowNetworkState:(BOOL)bShow{
    // 显示网络状态
    SAFE_EXEC_BLOCK_ON_MAIN_QUEUE(^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:bShow];
    });
    
}

#pragma mark interface

// 下载对应数据
- (NSData*)requestDataSync:(NSString *)path
{
//    DLog(@"khttp request path:%@", path);
    [self setShowNetworkState:YES];
    NSURL *url = [NSURL URLWithString:path];
    NSURLRequest *re = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:REQUEST_TIMEOUT];
    
    m_connet = [NSURLConnection connectionWithRequest:re delegate:self];
    
    
    while (1) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture] ];
        if (m_isFinished || m_isError) break;
    }
    [self setShowNetworkState:NO];
    return m_recvData;
}

// 下载对应数据
- (NSData*)requestDataWithPostSync:(NSString *)path{

//    NSLog(@"path:%@", path);
    NSURL *url = [NSURL URLWithString:path];
    NSMutableURLRequest *re = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:REQUEST_TIMEOUT];
    m_request = re;
    [re setHTTPMethod:@"POST"];
    m_connet = [NSURLConnection connectionWithRequest:re delegate:self];
    
    
    while (1) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture] ];
        if (m_isFinished || m_isError) break;
    }
    return m_recvData;
}

// post请求
- (NSData *)postDataSync:(NSString *)path withDic:(NSDictionary *)dicNeedPost{
    
    if (!dicNeedPost) {
        return nil;
    }
    NSError *err;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dicNeedPost options:NSJSONWritingPrettyPrinted error:&err];
    if (err) {
        DLog(@"jsons err:%@", err);
        return nil;
    }
    
//    NSLog(@"path:%@", path);
    NSURL *url = [NSURL URLWithString:path];
    NSMutableURLRequest *re = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:REQUEST_TIMEOUT];
    m_request = re;
    [re setHTTPMethod:@"POST"];
    [re setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [re setHTTPBody:data];

    m_connet = [NSURLConnection connectionWithRequest:re delegate:self];
    
    
    while (1) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture] ];
        if (m_isFinished || m_isError) break;
    }
    return m_recvData;
}

// post请求
- (NSData *)postFormDataSync:(NSString *)path withDic:(NSDictionary *)dicNeedPost{

    
    
//    NSLog(@"path:%@", path);
    NSURL *url = [NSURL URLWithString:path];
    NSMutableURLRequest *re = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:REQUEST_TIMEOUT];
    [re setHTTPMethod:@"POST"];
    m_request = re;
    
    if (dicNeedPost) {
        NSError *err;
        NSData *data = [NSJSONSerialization dataWithJSONObject:dicNeedPost options:NSJSONWritingPrettyPrinted error:&err];
        if (err) {
            DLog(@"jsons err:%@", err);
            return nil;
        }
        [KHttpRequest setFormDataRequest:re fromData:dicNeedPost];
    }
    
    if (m_dicHeaders) {
        NSArray *keys = m_dicHeaders.allKeys;
        for (NSString *key in keys) {
            [re setValue:[m_dicHeaders objectForKey:key] forHTTPHeaderField:key];
        }
    }
    
    m_connet = [NSURLConnection connectionWithRequest:re delegate:self];
    
    
    while (1) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture] ];
        if (m_isFinished || m_isError) break;
    }
    return m_recvData;
    
}

// put
- (BOOL)putDataSync:(NSString *)path withData:(NSData *)data{
//    NSLog(@"path:%@", path);
    NSURL *url = [NSURL URLWithString:path];
    NSMutableURLRequest *re = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:REQUEST_TIMEOUT];
    [re setHTTPMethod:@"PUT"];
    //[re setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [re setHTTPBody:data];
    m_request = re;

    if (m_dicHeaders) {
        NSArray *keys = m_dicHeaders.allKeys;
        for (NSString *key in keys) {
            [re setValue:[m_dicHeaders objectForKey:key] forHTTPHeaderField:key];
        }
    }
    
    m_connet = [NSURLConnection connectionWithRequest:re delegate:self];
    
    
    while (1) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture] ];
        if (m_isFinished || m_isError) break;
    }
    return m_statusCode == 200;
}

- (NSData *)testPost:(NSString *)path{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    [dic setObject:[NSString stringWithFormat:@"%d", 100] forKey:@"m"];
    [dic setObject:@"20435888" forKey:@"id"];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *json = [NSString stringWithCString:[jsonData bytes] encoding:NSUTF8StringEncoding];
    json = @"20435888-100";
    
    NSString *str = [NSString stringWithFormat:@"<?xml version=\"1.0\"?> <request><event>callreq</event><callid>60000000000008mRrDm254582</callid><accountid>aae25ec101fc12087516bc6564d0aa73</accountid><appid>0e0ad5c8ba5c4225b9eff2f4c0259196</appid><calltype>0</calltype><callertype>0</callertype><callerchargetype>0</callerchargetype><callerbalance>10.96</callerbalance><caller>60000000000008</caller><calledtype>1</calledtype><called>18612345678</called><userData>%@</userData></request>", json];
    
    NSError *err;
    NSData *data = [NSData dataWithBytes:str.UTF8String length:str.length];

//    NSLog(@"path:%@", path);
    NSURL *url = [NSURL URLWithString:path];
    NSMutableURLRequest *re = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:REQUEST_TIMEOUT];
    m_request = re;
    [re setHTTPMethod:@"POST"];
    [re setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [re setHTTPBody:data];
    m_connet = [NSURLConnection connectionWithRequest:re delegate:self];
    
    while (1) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture] ];
        if (m_isFinished || m_isError) break;
    }
    
    NSString *strRec = [NSString stringWithCString:[m_recvData bytes] encoding:NSUTF8StringEncoding];
    
    return m_recvData;
}

@end





