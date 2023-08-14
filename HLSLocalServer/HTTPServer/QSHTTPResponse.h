//
//  QSHTTPResponse.h
//  HLSLocalServer
//
//  Created by xuequan on 2023/8/4.
//

#import <Foundation/Foundation.h>
#import "HTTPConnection.h"
#import "HTTPResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface QSHTTPResponse : NSObject <HTTPResponse>

- (instancetype)initWithConnection:(HTTPConnection *)connection filePath:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
