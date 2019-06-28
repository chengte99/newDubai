//
//  CacheManager.h
//  DUBAIPALACE
//
//  Created by KevinLin on 2019/1/29.
//  Copyright © 2019 KevinLin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CacheManager : NSObject

- (NSString *)getCacheSizeWithFilePath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
