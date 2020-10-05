/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */


#import "CDVProxyHandler.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation CDVProxyHandler


- (instancetype)init
{
    self = [super init];
    return self;
}

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask
{
    self.isRunning = true;
    NSString * newScheme = @"";
    NSURL * url = urlSchemeTask.request.URL;
    NSDictionary * header = urlSchemeTask.request.allHTTPHeaderFields;
    NSString * finalUrl = @"";
    NSString * scheme = url.scheme;
    NSString * method = urlSchemeTask.request.HTTPMethod;
    NSData * body = urlSchemeTask.request.HTTPBody;
    
    if ([scheme isEqualToString:@"proxy"]) {
        newScheme = @"http";
    }
    
    if ([scheme isEqualToString:@"proxys"]) {
        newScheme = @"https";
    }
    
    finalUrl = [url.absoluteString stringByReplacingOccurrencesOfString:scheme withString:newScheme];
    NSURL * requestUrl = [NSURL URLWithString:finalUrl];
    WKWebsiteDataStore* dataStore = [WKWebsiteDataStore defaultDataStore];
    WKHTTPCookieStore* cookieStore = dataStore.httpCookieStore;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:method];
    [request setURL:requestUrl];
    if (body) {
        [request setHTTPBody:body];
    }
    [request setAllHTTPHeaderFields:header];
    [request setHTTPShouldHandleCookies:YES];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(error && self.isRunning) {
            NSLog(@"Proxy error: %@", error);
            [urlSchemeTask didFailWithError:error];
            return;
        }
        
        // set cookies to WKWebView
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        if(httpResponse) {
            NSArray* cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[httpResponse allHeaderFields] forURL:response.URL];
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:httpResponse.URL mainDocumentURL:nil];
            cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
            
            for (NSHTTPCookie* c in cookies)
            {
                dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                    //running in background thread is necessary because setCookie otherwise fails
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [cookieStore setCookie:c completionHandler:nil];
                    });
                });
            };
        }
        
        // Do not use urlSchemeTask if it has been closed in stopURLSchemeTask
        if(self.isRunning) {
            [urlSchemeTask didReceiveResponse:response];
            [urlSchemeTask didReceiveData:data];
            [urlSchemeTask didFinish];
        }
    }] resume];
}

- (void)webView:(nonnull WKWebView *)webView stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask
{
    self.isRunning = false;
    NSLog(@"Proxy stop");
}


@end
