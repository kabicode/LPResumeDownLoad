# LPResumeDownLoad
  一.支持
  
    基于AFNetWorking3.0
    MJExtension

  二.功能
  
    1.可实现断点续传功能。
    2.采用plist文件 本地保存下载进度。
    3.支持默认和自定义保存文件路径和文件名字。
    4.可删除本地缓存文件。
    5.支持多任务下载。

  三.使用方法
  
    1.初始化。
      [LPDownLoadManager manager];

    2.添加下载任务。
      - (LPDownLoadTask *)addDownLoadTaskWithURL:(NSString *)URL
                                 cacheName:(NSString *)cacheName
                                  progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                         completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler;

    3.续传
    [self.downloadTask resume];


    4.暂停
    [self.downloadTask cancel];

    5.删除
    [self.manager deleteDownLoadFileFromTaskModel:self.task completion:nil];


    
    具体请看Demo的使用

 四.已知不足
 
     1. 多任务下载仍然在测试阶段。
     2. 没有创建一个单独进程供他下载。
