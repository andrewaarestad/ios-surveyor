//
//  GpsInterface.h
//  Mapbox Example
//
//  Created by Andrew on 2/27/15.
//  Copyright (c) 2015 Mapbox / Development Seed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GpsEvent.h"
#import "GpsReceiver.h"


@protocol GpsInterfaceObserver <NSObject>

-(void)gpsReceiver:(GpsReceiver*)receiver event:(GpsEvent*)event;

@end

@interface GpsInterface : NSObject

+(void)addObserver:(id<GpsInterfaceObserver>)observer;
+(void)removeObserver:(id<GpsInterfaceObserver>)observer;

+(void)start;
+(void)stop;

@property NSHashTable *observers;

@end
