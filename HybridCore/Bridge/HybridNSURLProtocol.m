//
//  HybridNSURLProtocol.m
//  WKWebVIewHybridDemo
//
//  Created by shuoyu liu on 2017/1/16.
//  Copyright © 2017年 shuoyu liu. All rights reserved.
//

#import "HybridNSURLProtocol.h"
#import <UIKit/UIKit.h>
#import "NSHTTPURLResponse+Plus.h"


static NSString* const KHybridNSURLProtocolHKey = @"KHybridNSURLProtocol";
@interface HybridNSURLProtocol ()<NSURLSessionDelegate,NSURLSessionDataDelegate,NSURLSessionTaskDelegate>
@property (nonnull,strong) NSURLSessionDataTask *task;

@end


@implementation HybridNSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    NSLog(@"request.URL.absoluteString = %@",request.URL.absoluteString);
    NSString *scheme = [[request URL] scheme];
    if ( ([scheme caseInsensitiveCompare:@"http"]  == NSOrderedSame ||
          [scheme caseInsensitiveCompare:@"https"] == NSOrderedSame ))
    {
            //看看是否已经处理过了，防止无限循环
            if ([NSURLProtocol propertyForKey:KHybridNSURLProtocolHKey inRequest:request])
            {
                 return NO;
            }
        NSString *MIMETypeString = [self containMIMETypeWithURL:request.URL.absoluteString];
        if (MIMETypeString)  {
            return NO;
        }
            return YES;
       

    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    
    //request截取重定向 这个可以根据需求重新定向URL 我这没有需求，所以没处理
    if ([request.URL.absoluteString containsString:@"http://127.0.0.1:8008"])
    {
        NSString *MIMETypeString = [self containMIMETypeWithURL:request.URL.absoluteString];
        if (!MIMETypeString)  {
            
            NSArray *array =[request.URL.absoluteString componentsSeparatedByString:@"8008"];
            if (array.count==2) {
                NSString *str=[NSString stringWithFormat:@"http://192.168.1.186:8061%@",[array objectAtIndex:1]];
                NSURL* url1 = [NSURL URLWithString:str];
                 mutableReqeust = [NSMutableURLRequest requestWithURL:url1];
            }
            
           
        }
       
    }
    
    return mutableReqeust;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b
{
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading
{
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    //给我们处理过的请求设置一个标识符, 防止无限循环,
    [NSURLProtocol setProperty:@YES forKey:KHybridNSURLProtocolHKey inRequest:mutableReqeust];
    
   if ([self.request.URL.absoluteString containsString:@"http://127.0.0.1:8008"])
   {
           //这里处理页面里面发出的AJAX请求拦截处理。
//           NSString *MIMETypeString = [self containMIMETypeWithURL:self.request.URL.absoluteString];
//           if (!MIMETypeString)  {
//               NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
//               self.task = [session dataTaskWithRequest:self.request];
//               [self.task resume];
//           }
       
   }
//    //这里处理页面里面发出的AJAX请求拦截处理。
//    NSString *MIMETypeString = [self generateMIMETypeWithURL:self.request.URL.absoluteString];
//    if (!MIMETypeString)  {
//        NSArray *array =[self.request.URL.absoluteString componentsSeparatedByString:@"8008"];
//        if (array.count==2) {
//            NSString *str=[NSString stringWithFormat:@"http://192.168.1.186:8061%@",[array objectAtIndex:1]];
//            NSURL* url1 = [NSURL URLWithString:str];
//            mutableReqeust = [NSMutableURLRequest requestWithURL:url1];
//       
//        }
               NSString *MIMETypeString = [self containMIMETypeWithURL:self.request.URL.absoluteString];
               if (!MIMETypeString)  {
                   NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
                   self.task = [session dataTaskWithRequest:self.request];
                   [self.task resume];
    
       NSLog(@"没有网络，而且没有找到对应的资源,那就直接调用父类的该方法吧");
        
    }
    
    
    
  
}
/**
 * 生成 MIMEType
 */
-(NSString *) generateMIMETypeWithURL:(NSString *) URL {
    NSString *MIMETypeString = nil;
    
    if ([URL hasSuffix:@"html"]) {
        MIMETypeString = @"text/html";
    } else if ([URL hasSuffix:@"css"]) {
        MIMETypeString = @"text/css";
    } else if ([URL hasSuffix:@"js"]) {
        MIMETypeString = @"text/javascript";
    } else if ([URL hasSuffix:@"jpg"]) {
        MIMETypeString = @"image/jpeg";
    }else if ([URL hasSuffix:@"png"]) {
        MIMETypeString = @"image/png";
    } else if ([URL hasSuffix:@"pdf"]){
        MIMETypeString = @"application/pdf";
    } else if ([URL hasSuffix:@"pdf"]){
        MIMETypeString = @"audio/wav";
    }
    else {
        ;
    }
    
    return MIMETypeString;
}
-(NSString *) containMIMETypeWithURL:(NSString *) URL {
    NSString *MIMETypeString = nil;
    
    if ([URL containsString:@".html"]) {
        MIMETypeString = @"text/html";
    } else if ([URL containsString:@".css"]) {
        MIMETypeString = @"text/css";
    } else if ([URL containsString:@".js"]) {
        MIMETypeString = @"text/javascript";
    } else if ([URL containsString:@".jpg"]) {
        MIMETypeString = @"image/jpeg";
    }else if ([URL containsString:@".png"]) {
        MIMETypeString = @"image/png";
    } else if ([URL containsString:@".pdf"]){
        MIMETypeString = @"application/pdf";
    } else if ([URL containsString:@".pdf"]){
        MIMETypeString = @"audio/wav";
    }else if ([URL containsString:@".gif"]){
        MIMETypeString = @"image/gif";
    }
    else {
        ;
    }
    
    return MIMETypeString;
}
+(NSString *) containMIMETypeWithURL:(NSString *) URL {
    NSString *MIMETypeString = nil;
    
    if ([URL containsString:@".html"]) {
        MIMETypeString = @"text/html";
    } else if ([URL containsString:@".css"]) {
        MIMETypeString = @"text/css";
    } else if ([URL containsString:@".js"]) {
        MIMETypeString = @"text/javascript";
    } else if ([URL containsString:@".jpg"]) {
        MIMETypeString = @"image/jpeg";
    }else if ([URL containsString:@".png"]) {
        MIMETypeString = @"image/png";
    } else if ([URL containsString:@".pdf"]){
        MIMETypeString = @"application/pdf";
    } else if ([URL containsString:@".pdf"]){
        MIMETypeString = @"audio/wav";
    } else if ([URL containsString:@".gif"]){
        MIMETypeString = @"image/gif";
    }
    else {
        ;
    }
    
    return MIMETypeString;
}
+(NSString *) generateMIMETypeWithURL:(NSString *) URL {
    NSString *MIMETypeString = nil;
    
    if ([URL hasSuffix:@"html"]) {
        MIMETypeString = @"text/html";
    } else if ([URL hasSuffix:@"css"]) {
        MIMETypeString = @"text/css";
    } else if ([URL hasSuffix:@"js"]) {
        MIMETypeString = @"text/javascript";
    } else if ([URL hasSuffix:@"jpg"]) {
        MIMETypeString = @"image/jpeg";
    }else if ([URL hasSuffix:@"png"]) {
        MIMETypeString = @"image/png";
    } else if ([URL hasSuffix:@"pdf"]){
        MIMETypeString = @"application/pdf";
    } else if ([URL hasSuffix:@"pdf"]){
        MIMETypeString = @"audio/wav";
    } else {
        ;
    }
    
    return MIMETypeString;
}
+ (void)unmarkRequestAsIgnored:(NSMutableURLRequest *)request
{
    NSString *key = NSStringFromClass([self class]);
    [NSURLProtocol removePropertyForKey:key inRequest:request];
}
- (void)stopLoading
{
    if (self.task != nil)
    {
        [self.task  cancel];
    }
}
#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *_Nullable))completionHandler
{
    if ([self client] != nil && [self task] == task) {
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        [[self class] unmarkRequestAsIgnored:mutableRequest];
        [[self client] URLProtocol:self wasRedirectedToRequest:mutableRequest redirectResponse:response];
        
        NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
        [self.task cancel];
        [self.client URLProtocol:self didFailWithError:error];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    if ([self client] != nil && (_task == nil || _task == task)) {
        if (error == nil) {
            [[self client] URLProtocolDidFinishLoading:self];
        } else if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
            // Do nothing.
        } else {
            [[self client] URLProtocol:self didFailWithError:error];
        }
    }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    if ([self client] != nil && [self task] != nil && [self task] == dataTask) {
        NSHTTPURLResponse *URLResponse = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            URLResponse = (NSHTTPURLResponse *)response;
            URLResponse = [NSHTTPURLResponse rxr_responseWithURL:URLResponse.URL
                                                      statusCode:URLResponse.statusCode
                                                    headerFields:URLResponse.allHeaderFields
                                                 noAccessControl:YES];
        }
        NSLog(@"response---%@",response);
        [[self client] URLProtocol:self
                didReceiveResponse:URLResponse ?: response
                cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    if ([self client] != nil && [self task] == dataTask) {
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:nil];
        NSLog(@"json---%@",json);
        [[self client] URLProtocol:self didLoadData:data];
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *_Nullable cachedResponse))completionHandler
{
    if ([self client] != nil && [self task] == dataTask) {

        completionHandler(proposedResponse);
    }
}



@end
