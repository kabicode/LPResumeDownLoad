//
//  LPDownLoadTask.h
//  AFNetWorkResumeDownloadDemo
//
//  Created by onecampus on 15/12/29.
//  Copyright © 2015年 onecampus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPSessionManager.h"
#import "LPDownLoadModel.h"

#define WeakIfY(weakSelf)  __weak __typeof__(self) weakSelf = self
#define StrongIfY(strongSelf)  __strong __typeof__(weakSelf) strongSelf = weakSelf
@interface LPDownLoadTask : NSObject


@property (nonatomic, strong) LPDownLoadModel *downLoadModel;
//下载状态
@property (nonatomic, assign) NSURLSessionTaskState state;


- (LPDownLoadTask *)downLoadTaskWithModel:(LPDownLoadModel *)taskDetail
                           sessionManager:(AFHTTPSessionManager *)sessionManager
                                 progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                        completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler;


- (LPDownLoadTask *)downLoadTaskWithURL:(NSString *)URL
                         sessionManager:(AFHTTPSessionManager *)sessionManager;


- (LPDownLoadTask *)downLoadTaskWithURL:(NSString *)URL
                         sessionManager:(AFHTTPSessionManager *)sessionManager
                               progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock;


- (LPDownLoadTask *)downLoadTaskWithURL:(NSString *)urlString
                         sessionManager:(AFHTTPSessionManager *)sessionManager
                               progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                      completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler;
//暂停 可存活几分钟
//- (void)suspend;

//继续下载
- (void)resume;

//取消下载 一般用这个来暂停
- (void)cancel;

FOUNDATION_EXPORT NSString * const LPDownLoadTaskModelDidChange;
FOUNDATION_EXPORT NSString * const LPDownLoadTaskCompleted;
FOUNDATION_EXPORT NSString * const LPDownLoadTaskShouldRemove;
@end
