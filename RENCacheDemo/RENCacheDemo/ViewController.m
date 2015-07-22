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
    for (int a = 0 ; a < 20; a++) {
        
        [[RENCache sharedGlobalCache] setObjectValue:[NSNumber numberWithInt:a] forKey:[NSString stringWithFormat:@"%d",a]];
    }
    
//    NSLog(@"%@",[[RENCache sharedGlobalCache] allKeys]);
//    
//    //[[RENCache sharedGlobalCache] clearAllCache];
//    
//    NSLog(@"~~%@",[[RENCache sharedGlobalCache] allKeys]);
    
//    [[RENCache sharedGlobalCache] setObjectValue:@"aaa" forKey:@"0"];
    [[RENCache sharedGlobalCache] setSeavCacheToDisk];
    


    
//    [[RENCache sharedGlobalCache] clearAllCache];
//    [[RENCache sharedGlobalCache] setObjectValue:@[@"1",@"d"] forKey:@"hhhhh"];
//    NSLog(@"==%ld",(NSInteger)[[RENCache sharedGlobalCache] hasCacheForKey:@"hhhhh"]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
