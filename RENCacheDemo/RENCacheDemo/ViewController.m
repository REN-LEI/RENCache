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

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
