//
//  GpsInterface.h
//  Mapbox Example
//
//  Created by Andrew on 2/27/15.
//  Copyright (c) 2015 Mapbox / Development Seed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GpsLocation.h"

@protocol GpsInterfaceObserver <NSObject>

-(void)locationAvailable:(GpsLocation*)location;

@end

@interface GpsInterface : NSObject

+(void)addObserver:(id<GpsInterfaceObserver>)observer;
+(void)removeObserver:(id<GpsInterfaceObserver>)observer;

+(void)connect;

@property NSMutableArray *observers;

@end
