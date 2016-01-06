//
//  LPDownLoadManager.h
//  AFNetWorkResumeDownloadDemo
//
//  Created by onecampus on 15/12/29.
//  Copyright © 2015年 onecampus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPDownLoadTask.h"


@interface LPDownLoadManager : NSObject

@property (nonatomic, strong) NSMutableArray *downLoadTaskArray;
@property (nonatomic, strong) NSMutableArray *taskModelArray;

@property (nonatomic, copy) NSString *listName;


+ (instancetype)manager;

//存储的plist文件名
- (instancetype)initWithListName:(NSString *)ListName;



- (LPDownLoadTask *)addDownLoadTaskWithURL:(NSString *)URL
                                 cacheName:(NSString *)cacheName
                                  progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                         completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler;



- (LPDownLoadTask *)getDownLoadingTaskFromUrlString:(NSString *)urlString;


//删除任务（包括缓存文件）  可在下载过程中删除
- (void)deleteDownLoadFileFromTaskModel:(LPDownLoadModel *)taskModel
                             completion:(void (^)())completion;

@end
