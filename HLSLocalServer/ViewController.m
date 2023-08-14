//
//  ViewController.m
//  HLSLocalServer
//
//  Created by xuequan on 2023/8/4.
//

#import "ViewController.h"
#import <ZFPlayer/ZFPlayer.h>
#import <ZFPlayer/ZFPlayerControlView.h>
#import <ZFPlayer/ZFAVPlayerManager.h>
#import "HTTPServer.h"
#import "QSHTTPConnection.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *playerContainer;
@property (nonatomic, strong) ZFPlayerController *player;
@property (nonatomic, strong) ZFPlayerControlView *controlView;

@property (nonatomic, strong) HTTPServer *httpServer;
@property (nonatomic, strong) GCDWebServer *webServer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.player == nil) {
        [self setupVideoPlayer];
    }
}

- (void)setupVideoPlayer {
    ZFAVPlayerManager *playerManager = [[ZFAVPlayerManager alloc] init];
    playerManager.shouldAutoPlay = YES;

    ZFPlayerController *player = [[ZFPlayerController alloc] initWithPlayerManager:playerManager containerView:self.playerContainer];
    player.controlView = self.controlView;
    self.player = player;
    
}

- (IBAction)setupVideoUrl:(id)sender {
    
    NSString *videoUrl = @"https://live-par-2-abr.livepush.io/vod/bigbuckbunny/bigbuckbunny.840x480.mp4/tracks-v1a1/mono.m3u8";
    NSURL *localVideoUrl = [self parseRemoteUrlString:videoUrl];
    self.player.assetURL = localVideoUrl;

}

- (NSURL *)parseRemoteUrlString:(NSString *)urlStr {
    
    NSString *documentDirctory  = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;
    NSURL *originURL = [NSURL URLWithString:urlStr];
    // 文件夹
    NSString *resRelativeDirectory = [[originURL host] stringByAppendingString:[[originURL relativePath] stringByDeletingLastPathComponent]];
    NSString *resAbsDirectory = [NSString stringWithFormat:@"%@/%@", documentDirctory, resRelativeDirectory];
    // 资源本地路径
    NSString *resRelativePath = [NSString stringWithFormat:@"%@/%@", resRelativeDirectory, originURL.lastPathComponent];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:resAbsDirectory]) {
        // 如果没有文件夹，创建该文件夹
        [[NSFileManager defaultManager] createDirectoryAtPath:resAbsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSInteger port = 54321;
    if ([self.webServer isRunning]) {
        port = 54322;
    }else if ([self.httpServer isRunning]) {
        port = 54321;
    }
    
    NSString *localResStr = [NSString stringWithFormat:@"http://127.0.0.1:%@/%@",@(port), resRelativePath];
    return [NSURL URLWithString:localResStr];
}

- (IBAction)startCocoaHTTPServer:(id)sender {
    
    self.httpServer = [[HTTPServer alloc] init];
    NSString *documentDirctory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;
    NSLog(@"video server will start at path => %@", documentDirctory);
    [self.httpServer setType:@"_http._tcp."];
    [self.httpServer setPort:54321];
    [self.httpServer setConnectionClass:[QSHTTPConnection class]];
    [self.httpServer setDocumentRoot:documentDirctory];
    NSError *error = nil;
    if (![self.httpServer start:&error]) {
        NSLog(@"video server start occur error %@", error.localizedDescription);
    }else {
        NSLog(@"video server is started ");
    }
    
}

- (IBAction)startGCDWebServer:(id)sender {
    
    self.webServer = [[GCDWebServer alloc] init];
    // must add handler before start server.
    [self.webServer addDefaultHandlerForMethod:@"GET" requestClass:[GCDWebServerRequest class] asyncProcessBlock:^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock) {
        
        NSString *relativePath = request.URL.relativePath;
        NSString *documentDirctory  = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;
        NSString *localFilePath = [NSString stringWithFormat:@"%@%@", documentDirctory, relativePath];
        NSLog(@"will query local data path => %@",localFilePath);
        if ([[NSFileManager defaultManager] fileExistsAtPath:localFilePath]) {
            // 本地有文件
            NSString *mimeType = @"application/x-mpegurl";
            if ([localFilePath containsString:@".m3u8"]) {
                mimeType = @"application/x-mpegurl";
            }else if ([localFilePath containsString:@".ts"]) {
                mimeType = @"video/mp2t";
            }
            NSData *respData = [NSData dataWithContentsOfFile:localFilePath];
            completionBlock([[GCDWebServerDataResponse alloc] initWithData:respData contentType:mimeType]);
        }else {
            // 拼接远端视频文件链接，进行远程下载
            NSString *remoteUrlStr = [NSString stringWithFormat:@"https:/%@",relativePath];
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:remoteUrlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15];
            NSURLSession *session = [NSURLSession sharedSession];
            NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                // 出错了，发出错误响应
                GCDWebServerDataResponse *videoResponse = [[GCDWebServerDataResponse alloc] initWithStatusCode:500];
                if (error == nil && data != nil) {
                    // 写入本地 数据下载成功，发出数据响应
                    [data writeToFile:localFilePath atomically:YES];
                    videoResponse = [[GCDWebServerDataResponse alloc] initWithData:data contentType:response.MIMEType];
                }
                completionBlock(videoResponse);
            }];
            [task resume];
        }
        
    }];
    
    BOOL started = [self.webServer startWithPort:54322 bonjourName:@"hello gcd web server"];
    if (started) {
        NSLog(@"GCD web server is start port => %@", @(54322));
    }else {
        NSLog(@"GCD web server is start port error");
    }
    
}

- (ZFPlayerControlView *)controlView {
    if (!_controlView) {
        _controlView = [ZFPlayerControlView new];
        _controlView.fastViewAnimated = YES;
        _controlView.autoHiddenTimeInterval = 5;
        _controlView.autoFadeTimeInterval = 0.5;
        _controlView.prepareShowLoading = YES;
        _controlView.prepareShowControlView = NO;
        _controlView.showCustomStatusBar = YES;
    }
    return _controlView;
}


@end
