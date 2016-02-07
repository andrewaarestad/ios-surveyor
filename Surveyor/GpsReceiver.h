

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>


#define NRF8001_UART_SERVICE_UUID @"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define NRF8001_UART_CHARACTERISTIC_TX @"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define NRF8001_UART_CHARACTERISTIC_RX @"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"



@class GpsReceiver;
@protocol GpsReceiverDelegate <NSObject>

-(void)locationReceived:(CLLocation*)location;

@end

@interface GpsReceiver : NSObject

- (id)initWithPeripheral:(CBPeripheral *)peripheral delegate:(id<GpsReceiverDelegate>)delegate;

@property (weak) id<GpsReceiverDelegate>delegate;
@property CBPeripheral *peripheral;

@end
