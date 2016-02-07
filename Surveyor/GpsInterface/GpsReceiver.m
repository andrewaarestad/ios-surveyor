

#import "GpsReceiver.h"
#import "GpsInterface.h"

#include "NmeaParser.h"

@interface GpsReceiver () <CBPeripheralDelegate>

@end


//GpsReceiver * refToSelf;
//int cCallback()
//{
//    [refToSelf someMethod:someArg];
//}
id<GpsReceiverDelegate> delgRef;

void nmeaSentenceCallback(nmea_sentence_t *sentence)
{
    switch(sentence->type){
        case NMEA_SENTENCE_TYPE_RMC: {
            gnss_location_t location = processRMC(sentence->chars);
            //CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(location.latitude, location.longitude);
            //CLLocation *location = [[CLLocation alloc] initWithCoordinate:coord altitude:location.altitude horizontalAccuracy:location.horizontalAccuracy verticalAccuracy:location.verticalAccuracy course:location.course speed:location.speed timestamp:location.timestamp];
            CLLocation *iosLocation = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
            
            [delgRef locationReceived:iosLocation];
            
            NSLog(@"RMC: %s",sentence->chars);
            
        }
            break;
        default: {
            // Discard
        }
    }
}

void nmea_printf(const char* fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    printf(fmt,args);
    va_end(args);
}

@implementation GpsReceiver
{
    
    CBCharacteristic *_characteristicTx;
    CBCharacteristic *_characteristicRx;
}

- (id)initWithPeripheral:(CBPeripheral *)peripheral delegate:(id<GpsReceiverDelegate>)delegate
{
    self = [super init];
    if (self) {
        delgRef = delegate;
        _delegate = delegate;
        _peripheral = peripheral;
        _peripheral.delegate = self;
        
        [_peripheral discoverServices:nil];
    }
    return self;
}



- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"BLE: didDiscoverServices: %lu services.", (unsigned long)[peripheral.services count]);
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);

        return;
    }
    
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        NSLog(@"BLE: Found characteristic: %@ - value: %@", characteristic.UUID,characteristic.value);
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:NRF8001_UART_CHARACTERISTIC_TX]]) {
            
            _characteristicTx = characteristic;
            //[peripheral readValueForCharacteristic:characteristic];
            
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:NRF8001_UART_CHARACTERISTIC_RX]]) {
            
            _characteristicRx = characteristic;
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            nmeaParserInit(nmeaSentenceCallback, nmea_printf);
            
        }
        
        
        
    }
    
}


#pragma mark - Peripheral data callbacks

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    
    //NSString *stringFromData = [characteristic.value description];
    //NSLog(@"BLE: Rx: %@", stringFromData);
    
    if (_characteristicRx == characteristic) {
        
        // TODO: Handle bytes
        // receiveNmeaBytes: [characteristic.value bytes]
        
        //NSLog(@"Received bytes: %@",characteristic.value);
        
        const char *bytes = [characteristic.value bytes];
        
        for (int ii=0; ii<characteristic.value.length; ii++){
            receiveNmeaByte(bytes[ii]);
        }
        
    }
    
    
    
}


- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{    
    if (error) {
        NSLog(@"Error writing characteristic value: %@",
              [error localizedDescription]);
    } else {
        //NSLog(@"Wrote characteristic.");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error changing notification state: %@", error);
    }

    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    } else {
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@. ", characteristic);
    }
}





@end
