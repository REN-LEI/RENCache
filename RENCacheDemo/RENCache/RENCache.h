//
//  RENCache.h
//  RENCacheDemo
//
//  Created by renlei on 15/6/12.
//  Copyright (c) 2015年 renlei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RENCache : NSObject

/// 默认缓存过期时间无限,可设置缺省缓存时长（秒）
@property(nonatomic) NSTimeInterval defaultTimeoutInterval;
/// 内存中最大保存个数，缺省为10，（最常使用排序）
@property(nonatomic) NSInteger defaultCacheMemoryLimit;

/// 单利
+ (RENCache *)sharedGlobalCache;


/// 获取当前缓存下所有key（包含内存缓存）
- (NSArray *)allKeys;


/// 判断key是否有对应缓存（包含内存缓存）
- (BOOL)hasCacheForKey:(NSString *)key;


/// 将内存缓存保存到磁盘
- (void)setSeavCacheToDisk;


/// 获取全部缓存大小（磁盘）
- (CGFloat)getAllCacheSize;
/// 获取内存中的缓存大小
- (CGFloat)getMemoryCacheSize;
/// 获取单个磁盘缓存的大小
- (CGFloat)getSingleCacheSizeForKey:(NSString *)key;


/// 清除全部缓存（包括内存中的缓存）
- (void)clearAllCache;
/// 删除内存中的缓存
- (void)clearMemoryCache;
/// 删除单个磁盘缓存
- (void)removeCacheForKey:(NSString *)key;


/// 根据key读取写入的image
- (UIImage *)imageObjectForKey:(NSString *)key;
/// 根据key写入image
- (void)setImage:(UIImage *)image forKey:(NSString *)key;
/// 根据key写入image  @param timeoutInterval 设置缓存时长(秒)
- (void)setImage:(UIImage *)image forKey:(NSString *)key withTimeoutInterval:(NSTimeInterval)timeoutInterval;


/// 根据key读取value  @note 当获取对象是model时，model必须实现NSCoding协议
- (id)objectForKey:(NSString *)key;
/// 根据key写入value  @note 当value为自定义对象,必须实现NSCoding协议
- (void)setObjectValue:(id)value forKey:(NSString *)key;
/// 根据key写入value  @param timeoutInterval 设置缓存时长(秒) @note 当value为自定义对象,必须实现NSCoding协议
- (void)setObjectValue:(id)value forKey:(NSString *)key withTimeoutInterval:(NSTimeInterval)timeoutInterval;


@end
