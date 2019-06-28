//
//  CacheManager.m
//  DUBAIPALACE
//
//  Created by KevinLin on 2019/1/29.
//  Copyright © 2019 KevinLin. All rights reserved.
//

#import "CacheManager.h"

@implementation CacheManager

- (NSString *)getCacheSizeWithFilePath:(NSString *)path{
    NSArray *subPathArr = [[NSFileManager defaultManager] subpathsAtPath:path];
    NSString *filePath  = nil;
    NSInteger totleSize = 0;
    for (NSString *subPath in subPathArr){
        filePath =[path stringByAppendingPathComponent:subPath];
        BOOL isDirectory = NO;
        BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
        if (!isExist || isDirectory || [filePath containsString:@".DS"]){
            continue;
        }
        NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        NSInteger size = [dict[@"NSFileSize"] integerValue];
        totleSize += size;
    }
    NSString *totleStr = nil;
    if (totleSize > 1000 * 1000){
        totleStr = [NSString stringWithFormat:@"%.2fMB",totleSize / 1000.00f /1000.00f];
    }else{
        totleStr = [NSString stringWithFormat:@"%.2fKB",totleSize / 1000.00f ];
    }
    
    //    else if (totleSize > 1000){
    //        totleStr = [NSString stringWithFormat:@"%.2fKB",totleSize / 1000.00f ];
    //    }else{
    //        totleStr = [NSString stringWithFormat:@"%.2fB",totleSize / 1.00f];
    //    }
    return totleStr;
}

@end
