//
//  AxcDataCache.m
//  xiezhi-iOS
//
//  Created by Axc on 2017/12/6.
//  Copyright © 2017年 Axc. All rights reserved.
//

#import "AxcDataCache.h"

#define AxcDataCachePath            @"/Documents/AxcDataCache"
#define kAxcDataCache               @"AxcDataCache"
#define kAxcDefaultCacheFolder      @"AxcDefaultCacheFolder"

@implementation AxcDataCache

+ (id)AxcTool_sharedManager {
    static id instance;
    kDISPATCH_ONCE_BLOCK(^{
        instance = [self new];
    });
    return instance;
}

#pragma mark Axc的数据缓存器 ------------------

/** 获取缓存路径 */
+ (NSString *)AxcTool_getCachePath{
    return [NSString stringWithFormat:@"%@%@",NSHomeDirectory(),AxcDataCachePath];
}
/** 获取文件管理对象 */
+ (NSFileManager *)AxcTool_getfileManager{
    return [NSFileManager defaultManager];
}

/**
 将数据存入缓存器，默认文件夹名称
 @param data 数据对象
 @param saveKey 存的文件名/或者唯一标识
 */
+ (void)AxcTool_cacheSaveWithData:(NSData *)data
                          saveKey:(NSString *)saveKey{
    [self AxcTool_cacheSaveWithData:data saveKey:saveKey folderName:kAxcDefaultCacheFolder];
}

/**
 将数据存入缓存器，自定文件夹名称
 @param data 数据对象
 @param folderName 文件夹名称-自动创建
 @param saveKey 存的文件名/或者唯一标识
 */
+ (void)AxcTool_cacheSaveWithData:(NSData *)data
                          saveKey:(NSString *)saveKey
                       folderName:(NSString *)folderName{
    if (!folderName.length) folderName = kAxcDefaultCacheFolder;
    NSMutableString *filePath = [NSMutableString stringWithFormat:@"%@/%@",self.AxcTool_getCachePath,folderName];
    BOOL isSuccess = [self.AxcTool_getfileManager createDirectoryAtPath:filePath
                                            withIntermediateDirectories:YES
                                                             attributes:nil
                                                                  error:nil];
    if (!isSuccess) {AxcErrorObjLog(AxcLS(AxcFileCreateFailed));return;}
    saveKey = [AxcCalculateTool AxcTool_MD5WithStr:saveKey];
    [filePath appendFormat:@"/%@",saveKey];
    BOOL isWrite = [data writeToFile:filePath
                          atomically:YES];
    if (!isWrite) {AxcErrorObjLog(AxcLS(AxcFileWriteFailed)); }
}


/**
 将数据取出缓存器，默认文件夹名称
 @param saveKey 存的文件名/或者唯一标识
 @return 数据对象
 */
+ (NSData *)AxcTool_cacheGetDataWithSaveKey:(NSString *)saveKey{
    return [self AxcTool_cacheGetDataWithSaveKey:saveKey
                                      folderName:kAxcDefaultCacheFolder];
}

/**
 将数据取出缓存器，自定文件夹名称
 @param folderName 文件夹名称
 @param saveKey 存的文件名/或者唯一标识
 @return 数据对象
 */
+ (NSData *)AxcTool_cacheGetDataWithSaveKey:(NSString *)saveKey
                                 folderName:(NSString *)folderName{
    if (!folderName.length) folderName = kAxcDefaultCacheFolder;
    NSString *saveKey_MD5 = [AxcCalculateTool AxcTool_MD5WithStr:saveKey];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@/%@",self.AxcTool_getCachePath,folderName,saveKey_MD5];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data) {
        data = [NSData data];
        NSString *errorLog = [NSString stringWithFormat:@"%@\n错误存储Key值：%@\n错误文件目录：%@\n错误文件路径：%@",AxcLS(AxcGetFileFailed),
                              saveKey,folderName,filePath];
        AxcErrorObjLog(errorLog);
    }
    return data ; // 返回空转换会直接崩溃
}


/** 清除全部缓存 */
+ (void)AxcTool_clearAllDataCache{
    [self AxcTool_clearCacheWithFolderName:nil]; // 为空最后不会拼接
}

/** 清除默认文件夹下的缓存 */
+ (void)AxcTool_clearDefaultCacheFolderCache{
    [self AxcTool_clearCacheWithFolderName:kAxcDefaultCacheFolder];
}

/**
 清除某个文件夹下的数据缓存
 @param folderName 文件夹名称
 */
+ (void)AxcTool_clearCacheWithFolderName:(NSString *)folderName{
    NSString *dataFilePath = [NSString stringWithFormat:@"%@%@%@",self.AxcTool_getCachePath,
                              folderName.length?@"/":@"",
                              folderName];
    kDISPATCH_GLOBAL_QUEUE_DEFAULT(^{ // 分线程
        CGFloat foderSize = [AxcCalculateTool AxcTool_GetFolderFileSizeMBytesWithPath:dataFilePath];
        if (foderSize > CGFLOAT_MIN) { // 有一丢丢也要删除
            if ([self.AxcTool_getfileManager fileExistsAtPath:dataFilePath]) {
                NSArray * fileArray = [self.AxcTool_getfileManager subpathsAtPath:dataFilePath];
                for (NSString * fileName in fileArray) {
                    NSString * filePath = [dataFilePath stringByAppendingPathComponent:fileName];
                    [self.AxcTool_getfileManager removeItemAtPath:filePath error:nil];
                }
            }
        }
    });
    
}


@end
