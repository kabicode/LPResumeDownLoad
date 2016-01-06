//
//  LPDownLoadManager.m
//  AFNetWorkResumeDownloadDemo
//
//  Created by onecampus on 15/12/29.
//  Copyright © 2015年 onecampus. All rights reserved.
//

#import "LPDownLoadManager.h"
#define kDownLoadList @"DownLoadList.plist"
@interface LPDownLoadManager()

@property (nonatomic, copy) NSString *plishPath;


@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@property (nonatomic, strong) NSLock *lock;

@end

@implementation LPDownLoadManager

- (void)dealloc
{
    for (LPDownLoadTask *task in _downLoadTaskArray) {
        [task cancel];
    }
    [self removeNotifications];
    [self upDataPlistFile];
    NSLog(@"LPDownLoadManager ---------------- dealloc！！！！！！！！！");
}

+ (instancetype)manager
{
    return [[self alloc] initWithListName:nil];
}

- (instancetype)init
{
    self = [super init];
    return [self initWithListName:nil];
}

- (instancetype)initWithListName:(NSString *)ListName
{
    if (ListName == nil) {
        ListName = kDownLoadList;
    }
    
    self.plishPath = [self plishPathByName:ListName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.plishPath]) {
        [[NSFileManager defaultManager] createFileAtPath:self.plishPath contents:nil attributes:nil];
    }
    
    self.taskModelArray = [self taskModelArrayGetByPlish:self.plishPath];
    self.downLoadTaskArray = [NSMutableArray array];
    self.lock = [[NSLock alloc] init];
    
    [self addNotifications];
    
    return self;
}

#pragma mark-

- (void)addNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskDidCancel:) name:LPDownLoadTaskModelDidChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskDidCompletation:) name:LPDownLoadTaskCompleted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downLoadTaskShouleRemove:) name:LPDownLoadTaskShouldRemove object:nil];
}

- (void)removeNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LPDownLoadTaskModelDidChange object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LPDownLoadTaskCompleted object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LPDownLoadTaskShouldRemove object:nil];
}

- (void)taskDidCancel:(NSNotification *)notification
{
    LPDownLoadModel *model = notification.object;
    [self upDataTaskModel:model];
}

- (void)taskDidCompletation:(NSNotification *)notification
{
    LPDownLoadModel *model = notification.object;
    [self upDataTaskModel:model];
}


- (void)downLoadTaskShouleRemove:(NSNotification *)notification
{
    [self.lock lock];
    LPDownLoadTask *task = notification.object;
    [self.downLoadTaskArray removeObject:task];
    [self.lock unlock];
}


- (void)upDataTaskModel:(LPDownLoadModel *)model
{
    [self removeTaskModel:model];
    [self.taskModelArray addObject:model];
    [self upDataPlistFile];
}

- (void)removeTaskModel:(LPDownLoadModel *)task
{
    [self.lock lock];
    for (LPDownLoadModel *model in self.taskModelArray) {
        if ([model.urlString isEqualToString:task.urlString]) {
            [self.taskModelArray removeObject:model];
            break;
        }
    }
    [self.lock unlock];
}

#pragma mark - downLoadTask

- (LPDownLoadTask *)addDownLoadTaskWithURL:(NSString *)URL
                                 cacheName:(NSString *)cacheName
                                  progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                         completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
{
    __block LPDownLoadModel *model = nil;
    WeakIfY(weakSelf);
    [self findTaskModelWithUrlString:URL Complete:^(BOOL findOut, LPDownLoadModel *taskModel) {
        StrongIfY(strongSelf);
        if (findOut) {
            
            model = taskModel;
            
            //如果要多次下载同个URL
            if (![model.fileName isEqualToString:cacheName]) {
                model.fileName = cacheName;
            }
            
            if(model.totalUnitCount == nil)
            {
                return;
            }
            //更新进度条进度一次
            NSProgress *progress = [NSProgress progressWithTotalUnitCount:model.totalUnitCount.doubleValue];
            progress.completedUnitCount = model.completedUnitCount.doubleValue;
            dispatch_async(dispatch_get_main_queue(), ^{
                downloadProgressBlock(progress);
            });
            
        }else
        {
            model = [[LPDownLoadModel alloc]init];
            model.urlString = URL;
            model.fileName = cacheName;
            [strongSelf.taskModelArray addObject:model];
        }
    }];
    
    LPDownLoadTask *task = [[LPDownLoadTask alloc] downLoadTaskWithModel:model
                                                          sessionManager:self.sessionManager
                                                                progress:downloadProgressBlock
                                                       completionHandler:completionHandler];

    if (task) {
        [self.downLoadTaskArray addObject:task];
    }
    return task;
}

- (void)deleteDownLoadFileFromTaskModel:(LPDownLoadModel *)taskModel
                             completion:(void (^)())completion
{
    LPDownLoadTask *task = [self getDownLoadingTaskFromUrlString:taskModel.urlString];
    if (task.state == NSURLSessionTaskStateRunning) {
        [task cancel];
        task = nil;
    }
    
    taskModel.resumeString = nil;
    [self removeTaskModel:taskModel];
    [self upDataPlistFile];
    
    NSString *filePath = nil;
    filePath = taskModel.cacheName? [self tmpCacheFile:taskModel.cacheName]: [self domainFilePath:taskModel.fileName];
 
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    
    if (completion) {
        completion();
    }
}

- (LPDownLoadTask *)getDownLoadingTaskFromUrlString:(NSString *)urlString
{
    for (LPDownLoadTask *task in self.downLoadTaskArray) {
        if ([task.downLoadModel.urlString isEqualToString:urlString]) {
            return task;
        }
    }
    return nil;
}

#pragma mark- plish文件

- (NSString *)plishPathByName:(NSString *)ListName
{
    if (ListName == nil) {
        ListName = kDownLoadList;
    }
    
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *plishPath = [docPath stringByAppendingPathComponent:ListName];
    
    return plishPath;
}

- (NSMutableArray *)taskModelArrayGetByPlish:(NSString *)plishPath
{
    NSArray *array = [[NSArray alloc] initWithContentsOfFile:plishPath];
    return [NSMutableArray arrayWithArray:[LPDownLoadModel objectArrayWithKeyValuesArray:array]];
}

- (void)findTaskModelWithUrlString:(NSString *)urlString
                          Complete: (void (^)(BOOL findOut, LPDownLoadModel *taskModel))block
{
    for (LPDownLoadModel *taskModel in self.taskModelArray) {
        if ([taskModel.urlString isEqualToString:urlString]) {
            block(YES, taskModel);
            return;
        }
    }
    block(NO, nil);
}

- (void)upDataPlistFile
{
    NSArray *array = [LPDownLoadModel keyValuesArrayWithObjectArray:self.taskModelArray];
    [array writeToFile:self.plishPath atomically:YES];
}

#pragma mark-
- (NSString *)tmpCacheFile:(NSString *)cacheName
{
    NSString *tmpPath =  NSTemporaryDirectory();
    NSString *cacheFilePath = [tmpPath stringByAppendingString:cacheName];
    return cacheFilePath;
}

- (NSString *)domainFilePath:(NSString *)fileName
{
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *downLoadDir = [NSString stringWithFormat:@"%@/Download/", docPath];
    NSString *filePath = [downLoadDir stringByAppendingString:fileName];
    return filePath;
}


#pragma mark-
- (AFHTTPSessionManager *)sessionManager
{
    if (!_sessionManager) {
        _sessionManager = [AFHTTPSessionManager manager];
    }
    return _sessionManager;
}


@end
