//
//  QSHTTPConnection.m
//  HLSLocalServer
//
//  Created by xuequan on 2023/8/4.
//

#import "QSHTTPConnection.h"

@implementation QSHTTPConnection

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
    // 此处返回自定义的HTTP响应类
    return [[QSHTTPResponse alloc] initWithConnection:self filePath:path];
}

@end
