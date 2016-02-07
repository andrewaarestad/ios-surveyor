//
//  GpsInterface.m
//  Mapbox Example
//
//  Created by Andrew on 2/27/15.
//  Copyright (c) 2015 Mapbox / Development Seed. All rights reserved.
//

#import "GpsInterface.h"

@interface GpsInterface() <GpsReceiverDelegate, CBCentralManagerDelegate>

@end

@implementation GpsInterface
{
    CBCentralManager *_centralManager;
    GpsReceiver *_currentConnection;
}

+(GpsInterface*)instance
{
    static GpsInterface *sharedMgr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMgr = [[self alloc] init];
        
        
    });
    return sharedMgr;
}

+(void)addObserver:(id<GpsInterfaceObserver>)observer
{
    GpsInterface *shared = [self instance];
    [shared.observers addObject:observer];
}

+(void)removeObserver:(id<GpsInterfaceObserver>)observer
{
    GpsInterface *shared = [self instance];
    [shared.observers removeObject:observer];
}


+(void)start
{
    GpsInterface *interface = [self instance];
    [interface startScan];
}

+(void)stop
{
    [[self instance] stopScan];
}


- (id)init
{
    self = [super init];
    if (self) {
        // Start up the CBCentralManager
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        if ([[NSHashTable class] respondsToSelector:@selector(weakObjectsHashTable)]) {
            _observers = [NSHashTable weakObjectsHashTable];
        } else {
            _observers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        }
    }
    
    return self;
}

- (BOOL)ready
{
    if (_centralManager) {
        return _centralManager.state == CBCentralManagerStatePoweredOn;
    } else {
        return false;
    }
}


- (void)startScan
{
    if (_centralManager.state != CBCentralManagerStatePoweredOn){
        if (![_centralManager isScanning]){
            NSLog(@"Starting scan...");
            
            NSArray *services = @[[CBUUID UUIDWithString:NRF8001_UART_SERVICE_UUID]];
            
            
            [_centralManager scanForPeripheralsWithServices:services
                                                    options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO }];
        } else {
            NSLog(@"Already scanning...");
        }
    } else {
        NSLog(@"Central was not powered on when scan attempt was given.");
    }
}

- (void)stopScan
{
    [_centralManager stopScan];
}


#pragma mark - Central Methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if ([central state] == CBCentralManagerStatePoweredOff) {
        NSLog(@"BLE: CoreBluetooth BLE hardware is powered off");
    } else if ([central state] == CBCentralManagerStatePoweredOn) {
        NSLog(@"BLE: CoreBluetooth BLE hardware is powered on and ready");
        [self startScan];
    } else if ([central state] == CBCentralManagerStateUnauthorized) {
        NSLog(@"BLE: CoreBluetooth BLE state is unauthorized");
    } else if ([central state] == CBCentralManagerStateUnknown) {
        NSLog(@"BLE: CoreBluetooth BLE state is unknown");
    } else if ([central state] == CBCentralManagerStateUnsupported) {
        NSLog(@"BLE: CoreBluetooth BLE hardware is unsupported on this platform");
    } else {
        NSLog(@"BLE: Unknown central state.");
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    
    NSLog(@"BLE: Discovered peripheral: %@ w/ RSSI = %@", peripheral.name, RSSI);
    
    if ([peripheral.name containsString:@"Spark"]) {
        
        NSLog(@"BLE: Connecting to peripheral %@", peripheral);
        [_centralManager connectPeripheral:peripheral options:nil];
    } else {
        NSLog(@"Skipping unrecognized peripheral: %@", peripheral.name);
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"BLE: Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"didConnectPeripheral: %@", peripheral.name);
    
    if (_currentConnection != nil){
        [_centralManager cancelPeripheralConnection:_currentConnection.peripheral];
        _currentConnection = nil;
    }
    
    _currentConnection = [[GpsReceiver alloc] initWithPeripheral:peripheral delegate:self];
    
    [self stopScan];
}


#pragma mark - GpsReceiverDelegate

-(void)locationReceived:(CLLocation *)location
{
    GpsEvent *event = [[GpsEvent alloc] init];
    event.coord = location.coordinate;
    
    for (id<GpsInterfaceObserver> observer in _observers){
        if ([observer respondsToSelector:@selector(gpsReceiver:event:)]){
            [observer gpsReceiver:_currentConnection event:event];
        }
    }
}




@end
