//
//  GpsInterface.m
//  Mapbox Example
//
//  Created by Andrew on 2/27/15.
//  Copyright (c) 2015 Mapbox / Development Seed. All rights reserved.
//

#import "GpsInterface.h"

@implementation GpsInterface

+(GpsInterface*)sharedInstance
{
    static GpsInterface *sharedMgr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMgr = [[self alloc] init];
        sharedMgr.observers = [NSMutableArray array];
        
    });
    return sharedMgr;
}

+(void)addObserver:(id<GpsInterfaceObserver>)observer
{
    GpsInterface *shared = [self sharedInstance];
    [shared.observers addObject:observer];
}

+(void)removeObserver:(id<GpsInterfaceObserver>)observer
{
    GpsInterface *shared = [self sharedInstance];
    [shared.observers removeObject:observer];
}


+(void)connect
{
    // Integrate BLE code here
}

@end
