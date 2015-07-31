//
//  ViewController.m
//  RENCacheDemo
//
//  Created by renlei on 15/6/24.
//  Copyright (c) 2015年 renlei. All rights reserved.
//

#import "ViewController.h"
#import "RENCache.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    RENCache *cache = [RENCache sharedGlobalCache];
    cache.defaultTimeoutInterval = 15;
    
    for (int a = 0; a < 20; a++) {
        
        [cache setObjectValue:@(a) forKey:[NSString stringWithFormat:@"_%d",a]];
    }
    
    NSLog(@"cache allKeys =%@",[cache allKeys]);
    NSLog(@"== %@",[cache objectForKey:@"_1"]);
    
    if ([cache hasCacheForKey:@"_1"]) {
        
        NSLog(@"key _1 :存在");
    }
    
    if ([cache hasCacheForKey:@"1"]) {
        
    } else {
        NSLog(@"key 1 :不存在");
        
    }
    NSLog(@"=== %@",[cache objectForKey:@"_1"]);
    
    [cache removeCacheForKey:@"_1"];
    
    if ([cache hasCacheForKey:@"_1"]) {
        
        NSLog(@"key _1 :存在");
    } else {
        NSLog(@"key _1 :不存在");
    }
    NSLog(@"=== %@",[cache objectForKey:@"_1"]);
    
    [cache clearAllCache];
    NSLog(@"cache allKeys =%@",[cache allKeys]);
    
    
    NSData *data = [@"ddddddddd" dataUsingEncoding:NSUTF8StringEncoding];
    
    [cache setObjectValue:data forKey:@"data"];
    
    NSLog(@"data===%@",[cache objectForKey:@"data"]);
    
    NSLog(@"dataString == %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    [cache clearAllCache];
    
    
    NSLog(@"====================================================================");
    
    [cache setObjectValue:@"2222" forKey:@"22" withTimeoutInterval:5];
    
    NSLog(@"==== %@",[cache objectForKey:@"22"]);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"==== %@",[cache objectForKey:@"22"]);
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSLog(@"==== %@",[cache objectForKey:@"22"]);
    });
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
