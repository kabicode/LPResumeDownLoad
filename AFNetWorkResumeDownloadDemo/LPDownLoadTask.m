//
//  LPDownLoadTask.m
//  AFNetWorkResumeDownloadDemo
//
//  Created by onecampus on 15/12/29.
//  Copyright © 2015年 onecampus. All rights reserved.
//

#import "LPDownLoadTask.h"

typedef void(^DownloadProgressBlock)(NSProgress *downloadProgress);

typedef void(^DownloadCompletionBlock)(NSURLResponse *response, NSURL *filePath, NSError *error);

typedef NSURL *(^DownLoadDestinationBlock)(NSURL *targetPath, NSURLResponse *response);

NSString * const LPDownLoadTaskModelDidChange = @"LPDownLoadTaskModelDidChange";
NSString * const LPDownLoadTaskCompleted = @"LPDownLoadTaskCompleted";
NSString * const LPDownLoadTaskShouldRemove = @"LPDownLoadTaskShouldRemove";


@interface LPDownLoadTask()

//@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) NSURLSessionDownloadTask *downLoadTask;

//@property (nonatomic, copy) NSString *urlString;
@property(nonatomic, copy) NSString *filePath;

@property (nonatomic, copy) DownloadProgressBlock progressBlock;
@property (nonatomic, copy) DownLoadDestinationBlock destinationBlock;
@property (nonatomic, copy) DownloadCompletionBlock completionBlock;



@end

@implementation LPDownLoadTask

- (void)dealloc
{
//    [self cancel]; 需在VC里调用  在这调用会奔溃
    [self setCompletionBlock:nil];
    [self setDestinationBlock:nil];
    [self setProgressBlock:nil];
    [self setSessionManager:nil];
    [self setDownLoadTask:nil];

    NSLog(@"LPDownLoadTask --------- deallo");
}



- (LPDownLoadTask *)downLoadTaskWithURL:(NSString *)URL
                         sessionManager:(AFHTTPSessionManager *)sessionManager
{
    return  [self downLoadTaskWithURL:URL
                       sessionManager:sessionManager
                             progress:nil
                    completionHandler:nil];
}


- (LPDownLoadTask *)downLoadTaskWithURL:(NSString *)URL
                         sessionManager:(AFHTTPSessionManager *)sessionManager
                               progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
{
    return  [self downLoadTaskWithURL:URL
                       sessionManager:sessionManager
                             progress:downloadProgressBlock
                    completionHandler:nil];
}


- (LPDownLoadTask *)downLoadTaskWithURL:(NSString *)urlString
                         sessionManager:(AFHTTPSessionManager *)sessionManager
                               progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                      completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
{
    LPDownLoadModel *model = [[LPDownLoadModel alloc]init];
    model.urlString = urlString;
    
    [self downLoadTaskWithModel:model
                 sessionManager:sessionManager
                       progress:downloadProgressBlock
              completionHandler:completionHandler];
    return self;
}


- (LPDownLoadTask *)downLoadTaskWithModel:(LPDownLoadModel *)taskDetail
                           sessionManager:(AFHTTPSessionManager *)sessionManager
                                 progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                        completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
{
    self.downLoadModel = taskDetail;
    self.sessionManager = sessionManager;
    
    WeakIfY(weakSelf);
    
    self.progressBlock = ^(NSProgress *downloadProgress){
        StrongIfY(strongSelf);
        strongSelf.downLoadModel.totalUnitCount = @(downloadProgress.totalUnitCount);
        strongSelf.downLoadModel.completedUnitCount = @(downloadProgress.completedUnitCount);
        dispatch_async(dispatch_get_main_queue(), ^{
            downloadProgressBlock(downloadProgress);
        });
    };
    
    
    self.destinationBlock = ^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        StrongIfY(strongSelf);
        strongSelf.downLoadModel.cacheName = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:LPDownLoadTaskCompleted object:strongSelf.downLoadModel];
        
        NSString *filePath = [NSString stringWithFormat:@"file://%@",[strongSelf filePath]];
        return [NSURL URLWithString:filePath];
    };
    
    self.completionBlock = ^(NSURLResponse *response, NSURL *filePath, NSError *error)
    {
        StrongIfY(strongSelf);
        [[NSNotificationCenter defaultCenter] postNotificationName:LPDownLoadTaskShouldRemove object:strongSelf];
        completionHandler(response, filePath, error);
    };
    
    self.downLoadTask = [self getDownLoadTaskWithTaskModel:taskDetail];
    return self;
}

- (NSURLSessionDownloadTask *)getDownLoadTaskWithTaskModel:(LPDownLoadModel *)taskModel
{
    
    //如果下载文件已存在 检查文件是否完整
    if (taskModel.cacheName.length == 0 && [[NSFileManager defaultManager] fileExistsAtPath:[self filePath]]) {
        double fileSize = [self fileSizeForPath:[self filePath]];
        //        double cacheSize = [self fileSizeForPath:[self tmpCacheFile]];
        
        //下载完成
        if (fileSize == self.downLoadModel.completedUnitCount.doubleValue) {
            self.completionBlock(nil, [NSURL URLWithString:[self filePath]], nil);
            return nil;
        }else
        {
            //如果不完整 重新下载
            NSURLSessionDownloadTask *task = [self getDownLoadTaskByURLString:taskModel.urlString];
            return task;
        }
    }
    
    
    //如果是第一次
    if (taskModel.cacheName.length == 0 && taskModel.resumeString.length == 0)
    {
        NSURLSessionDownloadTask *task = [self getDownLoadTaskByURLString:taskModel.urlString];
        return task;
    }
    
    
    //如果下载一半
    if (taskModel.cacheName.length != 0 && taskModel.resumeString.length != 0) {
        //检查临时文件的完整性
        BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:[self tmpCacheFile]];
        BOOL fileComplete = taskModel.completedUnitCount.doubleValue == [self fileSizeForPath:[self tmpCacheFile]];
        if ( fileExist && fileComplete ) {
            NSURLSessionDownloadTask *task = [self.sessionManager downloadTaskWithResumeData:[taskModel.resumeString dataUsingEncoding:NSUTF8StringEncoding]
                                                                                    progress:self.progressBlock
                                                                                 destination:self.destinationBlock
                                                                           completionHandler:self.completionBlock];
            return task;
        }else
        {
            //如果不完整 删除临时文件 重新下载
            if (fileExist && taskModel.cacheName.length != 0) {
                [[NSFileManager defaultManager] removeItemAtPath:[self tmpCacheFile] error:nil];
            }
            NSURLSessionDownloadTask *task = [self getDownLoadTaskByURLString:taskModel.urlString];
            return task;
        }
    }
    //获取下载进度
    
    return nil;
}

- (NSURLSessionDownloadTask *)getDownLoadTaskByURLString:(NSString *)urlString
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.downLoadModel.urlString]];
    NSURLSessionDownloadTask *task = [self.sessionManager downloadTaskWithRequest:request
                                                                         progress:self.progressBlock
                                                                      destination:self.destinationBlock
                                                                completionHandler:self.completionBlock];
    return task;
}

#pragma mark-

- (void)resumeDownLoadTask
{
    if (self.downLoadTask) {
        if (self.downLoadTask.state == NSURLSessionTaskStateRunning) {
            return;
        }
    }
    else {
        self.downLoadTask = [self getDownLoadTaskWithTaskModel:self.downLoadModel];
    }
    
    [self.downLoadTask resume];
}

- (void)cancelDownLoadTask
{
    WeakIfY(weakSelf);  //在dealloc里调用时，不能用weak修饰，会被立刻释放
//    __block LPDownLoadTask *strongSelf = self;
    [self.downLoadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        StrongIfY(strongSelf);
        [strongSelf saveTaskModelWithResumeData:resumeData];
    }];
    [self setDownLoadTask:nil];
}


- (void)suspend
{
    [self.downLoadTask suspend];
}

- (void)resume
{
    [self resumeDownLoadTask];
}

- (void)cancel
{
    [self cancelDownLoadTask];
}

#pragma mark -

- (void)saveTaskModelWithResumeData:(NSData *)resumeData
{
    NSString *resumeString = [[NSString alloc]initWithData:resumeData encoding:NSUTF8StringEncoding];
    _downLoadModel.resumeString = resumeString;
    _downLoadModel.cacheName = [self cacheName];
    [[NSNotificationCenter defaultCenter] postNotificationName:LPDownLoadTaskModelDidChange object:_downLoadModel];
}


- (unsigned long long)fileSizeForPath:(NSString *)path {
    
    signed long long fileSize = 0;
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    if ([fileManager fileExistsAtPath:path]) {
        
        NSError *error = nil;
        
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        
        if (!error && fileDict) {
            
            fileSize = [fileDict fileSize];
        }
    }
    
    return fileSize;
}


#pragma mark-

- (NSString *)domainPath
{
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *downLoadDir = [NSString stringWithFormat:@"%@/Download/", docPath];
    //如果路径不存在 创建
    if (![[NSFileManager defaultManager] fileExistsAtPath:downLoadDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:downLoadDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return downLoadDir;
}

- (NSString *)filePath
{
    if (!_filePath) {
        NSString *fileName = _downLoadModel.fileName;
        if (_downLoadModel.fileName == nil) {
            fileName = [_downLoadModel.urlString componentsSeparatedByString:@"/"].lastObject;
        }
        _filePath = [[self domainPath] stringByAppendingString:fileName];
    }
    return _filePath;
}

- (NSString *)cacheName
{
    NSString *cacheName = [_downLoadModel.resumeString componentsSeparatedByString:@"<key>NSURLSessionResumeInfoTempFileName</key>\n\t<string>"].lastObject;
    cacheName = [cacheName componentsSeparatedByString:@"</string>"].firstObject;
    return cacheName;
}

- (NSString *)tmpCacheFile
{
    NSString *tmpPath =  NSTemporaryDirectory();
    NSString *cacheFilePath = [tmpPath stringByAppendingString:_downLoadModel.cacheName];
    return cacheFilePath;
}

- (NSURLSessionTaskState)state
{
    return self.downLoadTask.state;
}

@end
