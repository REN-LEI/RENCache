//
//  RENCache.m
//  RENCacheDemo
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

/// 磁盘中的缓存，plist管理
@property (strong, nonatomic) NSMutableDictionary *diskCachePlist;
/// 最近访问的内存中的缓存
@property (strong, nonatomic) NSMutableArray *recentlyAccessedKeys;
/// 内存中的缓存
@property (strong, nonatomic) NSMutableDictionary *memoryCacheInfo;

@property (strong, nonatomic) dispatch_queue_t cacheInfoQueue;

@end

@implementation RENCache

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter]
     removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        self.cacheInfoQueue = dispatch_queue_create("com.rencache.info", NULL);
        dispatch_queue_t priority = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_set_target_queue(priority, _cacheInfoQueue);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearMemoryCache) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
        self.defaultTimeoutInterval = 0;
        self.defaultCacheMemoryLimit = 10;
        
        self.recentlyAccessedKeys = [[NSMutableArray alloc] init];
        self.memoryCacheInfo = [[NSMutableDictionary alloc] init];
        
        self.diskCachePlist = [NSMutableDictionary dictionaryWithContentsOfFile:cachePathForKey(defaultPlist)];
        
        if (!_diskCachePlist) {
            
            self.diskCachePlist = [[NSMutableDictionary alloc] init];
        }
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if([fileManager fileExistsAtPath:defaultCachePath()]) {
            
            NSMutableArray *removedKeys = [[NSMutableArray alloc] init];
            
            NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate];
            
            dispatch_sync(_cacheInfoQueue, ^{
                
                for(NSString *key in _diskCachePlist.allKeys) {
                    
                    if ([_diskCachePlist[key] isKindOfClass:[NSDate class]]) {
                        
                        if([_diskCachePlist[key] timeIntervalSinceReferenceDate] <= now) {
                            
                            [fileManager removeItemAtPath:cachePathForKey(key) error:NULL];
                            [removedKeys addObject:key];
                        }
                    }
                }
                [self.diskCachePlist writeToFile:cachePathForKey(defaultPlist) atomically:YES];
            });
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
    
    return [temp allKeys];
}


#pragma mark -
#pragma mark - has methods
- (BOOL)hasCacheForKey:(NSString *)key {
    
    return [[NSFileManager defaultManager] fileExistsAtPath:cachePathForKey(key)];
}

#pragma mark -
#pragma mark - remove methods
- (void)clearAllCache {
    
    dispatch_sync(_cacheInfoQueue, ^{
        
        for(NSString* key in _diskCachePlist) {
            [[NSFileManager defaultManager] removeItemAtPath:cachePathForKey(key) error:NULL];
        }
        
        [self.diskCachePlist removeAllObjects];
        [self.diskCachePlist writeToFile:cachePathForKey(defaultPlist) atomically:YES];
        [self clearMemoryCache];
    });
    
}

- (void)clearMemoryCache {
    
    [self.recentlyAccessedKeys removeAllObjects];
    [self.memoryCacheInfo removeAllObjects];
}

- (void)removeCacheForKey:(NSString *)key {
    
    NSAssert(![key isEqualToString:defaultPlist] , @"RENCache.plist 不可以删除");
    
    dispatch_async(_cacheInfoQueue, ^{
        
        [[NSFileManager defaultManager] removeItemAtPath:cachePathForKey(key) error:NULL];
        [self.diskCachePlist removeObjectForKey:key];
        [self.diskCachePlist writeToFile:cachePathForKey(defaultPlist) atomically:YES];
        
        if (_memoryCacheInfo[key]) {
            
            [self.memoryCacheInfo removeObjectForKey:key];
            [self.recentlyAccessedKeys removeObject:key];
        }
    });
    
}

#pragma mark -
#pragma mark - image methods
- (UIImage *)imageObjectForKey:(NSString *)key {
    
    if (!key) {
        return nil;
    }
    
    __block NSData *data;
    dispatch_sync(_cacheInfoQueue, ^{
        data = [self objectForKey:key];
    });
    
    return [UIImage imageWithData:data];
}
- (void)setImage:(UIImage *)image forKey:(NSString *)key {
    
    [self setImage:image forKey:key withTimeoutInterval:0];
    
}
- (void)setImage:(UIImage *)image forKey:(NSString *)key withTimeoutInterval:(NSTimeInterval)timeoutInterval {
    
    if (!image || !key) {
        return;
    }
    
    NSData *data = UIImagePNGRepresentation(image);
    data = data?data:UIImageJPEGRepresentation(image, 1.0f);
    [self setObjectValue:data forKey:key withTimeoutInterval:timeoutInterval];
}

#pragma mark -
#pragma mark - object methods
- (id)objectForKey:(NSString *)key {
    
    if (!key) {
        return nil;
    }
    __block NSData *data;
    
    dispatch_sync(_cacheInfoQueue, ^{
        
        data = [_memoryCacheInfo objectForKey:key];
        
        if (!data) {
            data = [NSData dataWithContentsOfFile:cachePathForKey(key) options:0 error:NULL];
        }
    });
    
    if (data) {
        
        [self setMemoryCacheData:data forKey:key];
        
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    return nil;
}

- (void)setObjectValue:(id)value forKey:(NSString *)key {
    
    [self setObjectValue:value forKey:key withTimeoutInterval:_defaultTimeoutInterval];
}

- (void)setObjectValue:(id)value forKey:(NSString *)key withTimeoutInterval:(NSTimeInterval)timeoutInterval {

    if (!value || !key) {
        return;
    }
    
    [self setDataValue:[NSKeyedArchiver archivedDataWithRootObject:value] forKey:key withTimeoutInterval:timeoutInterval];
}

#pragma mark -
#pragma mark - data methods
- (void)setDataValue:(NSData *)value forKey:(NSString*)key withTimeoutInterval:(NSTimeInterval)timeoutInterval {
    
    NSAssert(![key isEqualToString:defaultPlist] , @"RENCache.plist 不可保存或修改默认的plist");
    
    dispatch_sync(_cacheInfoQueue, ^{
        
        [value writeToFile:cachePathForKey(key) atomically:YES];
        id obj = timeoutInterval > 0 ? [NSDate dateWithTimeIntervalSinceNow:timeoutInterval] : @0;
        [self.diskCachePlist setObject:obj forKey:key];
        [self.diskCachePlist writeToFile:cachePathForKey(defaultPlist) atomically:YES];
    });
    
    [self setMemoryCacheData:value forKey:key];
    
}
#pragma mark -
#pragma mark - memory methods
- (void)setMemoryCacheData:(NSData *)data forKey:(NSString *)key {
    
    dispatch_sync(_cacheInfoQueue, ^{
        
        [self.memoryCacheInfo setObject:data forKey:key];
        
        if ([_recentlyAccessedKeys containsObject:key]) {
            
            [self.recentlyAccessedKeys removeObject:key];
        }
        
        [self.recentlyAccessedKeys insertObject:key atIndex:0];
        
        if (_recentlyAccessedKeys.count > _defaultCacheMemoryLimit) {
            
            NSString *leastRecentlyUsedKey = [_recentlyAccessedKeys lastObject];
            [self.recentlyAccessedKeys removeLastObject];
            [self.memoryCacheInfo removeObjectForKey:leastRecentlyUsedKey];
        }
    });
}


@end
