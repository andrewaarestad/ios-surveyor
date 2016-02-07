//
//  AppDelegate.m
//  Surveyor
//
//  Created by Andrew on 2/27/15.
//  Copyright (c) 2015 AAE. All rights reserved.
//

#import "AppDelegate.h"

//#import "Mapbox.h"
#import <Fabric/Fabric.h>
#import <Mapbox/Mapbox.h>

#import <Crashlytics/Crashlytics.h>


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Fabric with:@[[Crashlytics class], [MGLAccountManager class]]];



    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {

}

- (void)applicationDidEnterBackground:(UIApplication *)application {

}

- (void)applicationWillEnterForeground:(UIApplication *)application {

}

- (void)applicationDidBecomeActive:(UIApplication *)application {

}

- (void)applicationWillTerminate:(UIApplication *)application {

}


@end
