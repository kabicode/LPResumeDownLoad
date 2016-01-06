//
//  ViewController.m
//  AFNetWorkResumeDownloadDemo
//
//  Created by onecampus on 15/12/22.
//  Copyright © 2015年 onecampus. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"
#import "LPDownLoadManager.h"
//#define WeakIfY(weakSelf)  __weak __typeof__(self) weakSelf = self;
//#define StrongIfY(strongSelf)  __strong __typeof__(weakSelf) strongSelf = weakSelf;

typedef void (^LPDownLoadCompletion)(NSURLResponse *response, NSURL *filePath, NSError *error);

@interface ViewController ()

@property (nonatomic, strong) LPDownLoadManager *manager;

@property (nonatomic, strong) LPDownLoadTask *downloadTask;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (nonatomic, copy) LPDownLoadCompletion completionBlock;

@property (nonatomic, strong) NSMutableDictionary *resumeDataDic;
@property (nonatomic, strong) NSURL *requestURL;

@end

@implementation ViewController

- (void)viewWillDisappear:(BOOL)animated
{
    [self.downloadTask cancel];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.manager = [LPDownLoadManager manager];
    [self initDownLoadOperation];
}


- (void)initDownLoadOperation
{
    
    __weak __typeof__(self) weakSelf = self;
//    NSString *URL = @"http://m2.pc6.com/mac/iStatMenus.dmg";
//    NSString *URL = @"http://www.goobz.cn/uploadfile/2015/0208/20150208102315876.jpg";
    NSString *URL = @"http://baobab.cdn.wandoujia.com/1447163643457322070435.mp4";
    //cacheName 为nil时  默认截取url作为文件名
    self.downloadTask = [self.manager addDownLoadTaskWithURL:URL cacheName:@"hot.mp4" progress:^(NSProgress *downloadProgress) {
//        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof__(weakSelf) strongSelf = weakSelf;
            CGFloat progress = downloadProgress.completedUnitCount*1.0/downloadProgress.totalUnitCount*1.0;
            //            NSLog(@"progress---------------%f", progress);
            [strongSelf.progressView setProgress:progress animated:YES];
            NSLog(@"%f", progress);
//        });
        
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
//        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if(error)
        {
            //网络错误处理
            NSLog(@"%@", error);
        }
        NSLog(@"completion!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        NSLog(@"path = %@", NSHomeDirectory());
    }];
    
}



- (IBAction)resume:(id)sender {
    
//    [self initDownLoadOperation];
//    LPDownLoadTask *task =  self.manager.downLoadTaskArray.lastObject;
    [self.downloadTask resume];
}



- (IBAction)pause:(id)sender {
    
//    LPDownLoadTask *task =  self.manager.downLoadTaskArray.lastObject;
//    [task cancel];
    [self.downloadTask cancel];
}


- (IBAction)deleteTask:(id)sender {
    [self.manager deleteDownLoadFileFromTaskModel:self.manager.taskModelArray.firstObject completion:nil];
    self.downloadTask = nil;
}

- (LPDownLoadManager *)manager
{
    if (!_manager) {
        _manager = [LPDownLoadManager manager];
    }
    return _manager;
}



@end
