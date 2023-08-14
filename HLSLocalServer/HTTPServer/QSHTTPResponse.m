//
//  QSHTTPResponse.m
//  HLSLocalServer
//
//  Created by xuequan on 2023/8/4.
//

#import "QSHTTPResponse.h"

@interface QSHTTPResponse()

@property (nonatomic, strong) NSData *responseData;
@property (nonatomic, strong) HTTPConnection *connection;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, assign) BOOL doneRespond;

@end

@implementation QSHTTPResponse

- (instancetype)initWithConnection:(HTTPConnection *)connection filePath:(NSString *)filePath {
    
    if (connection == nil || filePath == nil) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.connection = connection;
        self.filePath = filePath;
    }
    
    NSString *documentDirctory  = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;
    NSString *localFilePath = [NSString stringWithFormat:@"%@%@", documentDirctory, filePath];
    NSLog(@"will query local data path => %@",localFilePath);
    if ([[NSFileManager defaultManager] fileExistsAtPath:localFilePath]) {
        // 本地有文件
        self.responseData = [NSData dataWithContentsOfFile:localFilePath];
    }else {
        // 去下载
        NSString *remoteUrlStr = [NSString stringWithFormat:@"https:/%@",filePath];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:remoteUrlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            if (error != nil) {
                // 出错了，发出错误响应
                [self.connection responseDidAbort:self];
                return;
            }
            // 数据下载成功，发出数据响应
            self.responseData = data;
            [self.connection responseHasAvailableData:self];
            // 写入本地
            [data writeToFile:localFilePath atomically:YES];
            
                    
        }];
        [task resume];
    }
    return self;
    
}

- (BOOL)delayResponseHeaders {
    // 是否延迟发送响应
    BOOL wait = self.responseData == nil;
    return wait;
}

- (UInt64)contentLength {
    return self.responseData.length;
}

- (BOOL)isDone {
    return self.doneRespond;
}

- (UInt64)offset {
    return 0;
}

- (NSData *)readDataOfLength:(NSUInteger)length {
    // 这里connection读完响应数据后，就代表此次链接结束
    if (self.responseData != nil) {
        self.doneRespond = YES;
    }
    return self.responseData;
}

- (void)setOffset:(UInt64)offset {
    
}

@end
