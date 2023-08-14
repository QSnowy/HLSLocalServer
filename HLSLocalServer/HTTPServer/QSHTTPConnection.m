//
//  QSHTTPConnection.m
//  HLSLocalServer
//
//  Created by xuequan on 2023/8/4.
//

#import "QSHTTPConnection.h"

@implementation QSHTTPConnection

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
    
    return [[QSHTTPResponse alloc] initWithConnection:self filePath:path];
}

@end
