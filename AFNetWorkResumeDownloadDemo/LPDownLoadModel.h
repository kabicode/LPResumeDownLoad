//
//  LPDownLoadModel.h
//  AFNetWorkResumeDownloadDemo
//
//  Created by onecampus on 15/12/30.
//  Copyright © 2015年 onecampus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MJExtension.h"
@interface LPDownLoadModel : NSObject

@property (nonatomic, copy) NSString *urlString;
//下载完成后的文件名
@property (nonatomic, copy) NSString *fileName;
//缓存时的文件名字
@property (nonatomic, copy) NSString *cacheName;

//@property (nonatomic, copy) NSString *filePath;
//@property (nonatomic, copy) NSString *cachePath;

@property (nonatomic, copy) NSString *resumeString;

@property (nonatomic, strong) NSNumber *completedUnitCount;
@property (nonatomic, strong) NSNumber *totalUnitCount;

@end
