//
//  RENCache.m
//  RENCacheManage
//
//  Created by renlei on 15/6/12.
//  Copyright (c) 2015年 renlei. All rights reserved.
//

#import "RENCache.h"

static NSString *const defaultPlist = @"RENCache.plist";

static inline NSString *defaultCachePath() {
    NSString *cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    return  [[[cachesDirectory stringByAppendingPathComponent:[[NSProcessInfo processInfo] processName]] stringByAppendingPathComponent:@"RENCache"] copy];
}

static inline NSString *cachePathForKey(NSString* key) {
    return [[defaultCachePath() stringByAppendingPathComponent:key] copy];
}

@interface RENCache ()

// 磁盘中的缓存，plist管理
@property (strong, nonatomic) NSMutableDictionary *diskCachePlist;
// 内存中的plist
@property (strong, nonatomic) NSMutableDictionary *memoryCachePlist;
// 最近访问的内存中的缓存
@property (strong, nonatomic) NSMutableArray *recentlyAccessedKeys;
// 内存中的缓存
@property (strong, nonatomic) NSMutableDictionary *memoryCacheInfo;

@end

@implementation RENCache

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter]
     removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setSeavCacheToDisk) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setSeavCacheToDisk) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setSeavCacheToDisk) name:UIApplicationWillTerminateNotification object:nil];
        
        self.defaultTimeoutInterval = 0;
        self.defaultCacheMemoryLimit = 10;
        
        self.recentlyAccessedKeys = [[NSMutableArray alloc] init];
        self.memoryCacheInfo = [[NSMutableDictionary alloc] init];
        self.memoryCachePlist = [[NSMutableDictionary alloc] init];
        
        self.diskCachePlist = [NSMutableDictionary dictionaryWithContentsOfFile:cachePathForKey(defaultPlist)];
        
        if (!_diskCachePlist) {
            
            self.diskCachePlist = [[NSMutableDictionary alloc] init];
        }
        NSLog(@"%@",defaultCachePath());
        NSFileManager *fileManager = [NSFileManager defaultManager];

        if([fileManager fileExistsAtPath:defaultCachePath()]) {
            
            NSMutableArray *removedKeys = [[NSMutableArray alloc] init];
            
            NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate];
            
            for(NSString *key in _diskCachePlist.allKeys) {
                
                if ([_diskCachePlist[key] isKindOfClass:[NSDate class]]) {
                    
                    if([_diskCachePlist[key] timeIntervalSinceReferenceDate] <= now) {
                        
                        [fileManager removeItemAtPath:cachePathForKey(key) error:NULL];
                        [removedKeys addObject:key];
                    }
                }
                
            }
           
            
            [self.diskCachePlist removeObjectsForKeys:removedKeys];
  
        } else {
            
            [fileManager createDirectoryAtPath:defaultCachePath() withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return self;
}

+ (RENCache *)sharedGlobalCache {
    
    static RENCache *instanceCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instanceCache = [[[self class] alloc] init];
    });
    
    return instanceCache;
}

#pragma mark -
#pragma mark - cacheSize methods
- (CGFloat)getAllCacheSize {
    
    NSUInteger size = 0;
    
    for (NSString *key in self.allKeys) {
    
        NSString *path = cachePathForKey(key);
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        size += [attrs fileSize];
    }
    return size;
}

- (CGFloat)getMemoryCacheSize {
    
    return [_memoryCacheInfo fileSize];
}

- (CGFloat)getSingleCacheSizeForKey:(NSString *)key {
    
    NSUInteger size = 0;
    
    NSFileManager* manager = [NSFileManager defaultManager];
    
    if ([manager fileExistsAtPath:cachePathForKey(key)]) {
        
        size = ([[manager attributesOfItemAtPath:cachePathForKey(key) error:nil] fileSize]);
    }
    
    return size;
}



#pragma mark -
#pragma mark - getAllKeys methods
- (NSArray *)allKeys {

    NSMutableDictionary *temp = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary *)_diskCachePlist];
    [temp addEntriesFromDictionary:_memoryCachePlist];
    return [temp allKeys];
}


#pragma mark -
#pragma mark - has methods
- (BOOL)hasCacheForKey:(NSString *)key {
    
    return [_memoryCacheInfo objectForKey:key] || [[NSFileManager defaultManager] fileExistsAtPath:cachePathForKey(key)]?YES:NO;
}

#pragma mark -
#pragma mark - seavCache methods
- (void)setSeavCacheToDisk {
    
    // 将内存中的保存到磁盘 plist同步，用于计算缓存过期，同时需要清除内存中的缓存
    for (NSString *key in [_memoryCacheInfo allKeys]) {
        
        [self.memoryCacheInfo[key] writeToFile:cachePathForKey(key) atomically:YES];
    }
    
    [self.diskCachePlist addEntriesFromDictionary:(NSDictionary *)_memoryCachePlist];
    [self.diskCachePlist writeToFile:cachePathForKey(defaultPlist) atomically:YES];
    [self.memoryCachePlist removeAllObjects];
    [self.memoryCacheInfo removeAllObjects];
    
}

#pragma mark -
#pragma mark - remove methods
- (void)clearAllCache {
    
    for(NSString* key in _diskCachePlist) {
        [[NSFileManager defaultManager] removeItemAtPath:cachePathForKey(key) error:NULL];
    }
    
    [self.diskCachePlist removeAllObjects];
    [self.diskCachePlist writeToFile:cachePathForKey(defaultPlist) atomically:YES];
    
    [self clearMemoryCache];
}

- (void)clearMemoryCache {
    
    [self.recentlyAccessedKeys removeAllObjects];
    [self.memoryCachePlist removeAllObjects];
    [self.memoryCacheInfo removeAllObjects];
}

- (void)removeCacheForKey:(NSString *)key {
    
    NSAssert(![key isEqualToString:defaultPlist] , @"RENCache.plist is a reserved key and can not be modified");
    
    [[NSFileManager defaultManager] removeItemAtPath:cachePathForKey(key) error:NULL];
    
    if (_memoryCacheInfo[key]) {
        
        [self.memoryCacheInfo removeObjectForKey:key];
        [self.memoryCachePlist removeObjectForKey:key];
        [self.recentlyAccessedKeys removeObject:key];
    }

}

#pragma mark -
#pragma mark - object methods
- (id)objectForKey:(NSString *)key {
    
    NSData *data = [_memoryCacheInfo objectForKey:key]?[_memoryCacheInfo objectForKey:key]:[NSData dataWithContentsOfFile:cachePathForKey(key) options:0 error:NULL];
    
    if (data) {
        
        [self setMemoryCacheData:data forKey:key withTimeoutInterval:0];
        
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    
    return nil;
}

- (void)setObjectValue:(id)value forKey:(NSString *)key {
    
    [self setObjectValue:value forKey:key withTimeoutInterval:_defaultTimeoutInterval];
}

- (void)setObjectValue:(id)value forKey:(NSString *)key withTimeoutInterval:(NSTimeInterval)timeoutInterval {
    
    [self setDataValue:[NSKeyedArchiver archivedDataWithRootObject:value] forKey:key withTimeoutInterval:timeoutInterval];
}

#pragma mark -
#pragma mark - data methods
- (void)setDataValue:(NSData *)value forKey:(NSString*)key withTimeoutInterval:(NSTimeInterval)timeoutInterval {
    
    NSAssert(![key isEqualToString:defaultPlist] , @"RENCache.plist is a reserved key and can not be modified");

    [self setMemoryCacheData:value forKey:key withTimeoutInterval:timeoutInterval];
    
}
#pragma mark -
#pragma mark - memory methods
- (void)setMemoryCacheData:(NSData *)data forKey:(NSString *)key  withTimeoutInterval:(NSTimeInterval)timeoutInterval {
    
    // 先加入内存缓存中
    id obj = timeoutInterval > 0 ? [NSDate dateWithTimeIntervalSinceNow:timeoutInterval] : @0;

    [self.memoryCachePlist setObject:obj forKey:key];
    [self.memoryCacheInfo setObject:data forKey:key];
    
    // 判断当前内存缓存中是否存在
    if ([_recentlyAccessedKeys containsObject:key]) {
        // 存在删除
        [self.recentlyAccessedKeys removeObject:key];
    }
    // 插入到数组第0个元素
    [self.recentlyAccessedKeys insertObject:key atIndex:0];
    
    // 判断最近访问的缓存中是否大于默认的缓存个数
    if (_recentlyAccessedKeys.count > _defaultCacheMemoryLimit) {
        
        // 将最后一个缓存存入磁盘
        NSString *leastRecentlyUsedKey = [_recentlyAccessedKeys lastObject];
        NSData *leastRecentlyUsedData = [_memoryCacheInfo objectForKey:leastRecentlyUsedKey];
        [leastRecentlyUsedData writeToFile:cachePathForKey(leastRecentlyUsedKey) atomically:YES];
        // 删除内存中的最后一个缓存
        [self.recentlyAccessedKeys removeLastObject];
        [self.memoryCacheInfo removeObjectForKey:leastRecentlyUsedKey];
        // 将对应的内存中的plist保存到磁盘
        [self.diskCachePlist setObject:_memoryCachePlist[leastRecentlyUsedKey] forKey:leastRecentlyUsedKey];
        [self.diskCachePlist writeToFile:cachePathForKey(defaultPlist) atomically:YES];
    }
    
}


@end
