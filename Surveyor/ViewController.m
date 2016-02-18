//
//  ViewController.m
//  Surveyor
//
//  Created by Andrew on 2/27/15.
//  Copyright (c) 2015 AAE. All rights reserved.
//

#import "ViewController.h"

//#import "Mapbox.h"
#import "GpsInterface.h"
#import <Mapbox/Mapbox.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreGraphics/CGBase.h>

#define kMapboxMapID @"gathius.lb5ncnhg"

@interface ViewController () <GpsInterfaceObserver, MGLMapViewDelegate, CLLocationManagerDelegate>

@property (nonatomic) MGLMapView *map;
@property (nonatomic,strong) CLLocationManager *locationManager;

@end

@implementation ViewController
{
    MGLPointAnnotation *_currentLocation;
    BOOL _hasDoneInitialZoom;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _hasDoneInitialZoom = NO;
    
    
    if ([CLLocationManager locationServicesEnabled]) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        [self.locationManager startUpdatingLocation];
    } else {
        NSLog(@"Location services are not enabled");
    }
    
    
    
    self.map = [[MGLMapView alloc] initWithFrame:self.view.bounds];
    self.map.delegate = self;
    [self.map setStyleURL:[MGLStyle satelliteStyleURL]];
    [self.map setCenterCoordinate:CLLocationCoordinate2DMake(46, -94)
                        zoomLevel:6
                         animated:NO];
    
    [self.view addSubview:self.map];
    
    
    
    [self drawMultipolygon:[[NSBundle mainBundle] pathForResource:@"01_us_states" ofType:@"geojson"] restricted:NO];
    [self drawMultipolygon:[[NSBundle mainBundle] pathForResource:@"becker_county_mn_parcels" ofType:@"geojson"] restricted:YES];
    
    
    

    
    [GpsInterface addObserver:self];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [GpsInterface start];
    [GpsInterface addObserver:self];
    
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:46.73275 longitude:-95.81665];
    
    [self.map setCenterCoordinate:location.coordinate
                        zoomLevel:13
                         animated:NO];
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [GpsInterface stop];
    [GpsInterface removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (BOOL)mapView:(__unused MGLMapView *)mapView annotationCanShowCallout:(__unused id <MGLAnnotation>)annotation {
    return YES;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    /*
    if (!_hasDoneInitialZoom){
        CLLocation *location = [locations lastObject];
        
        [self.map setCenterCoordinate:location.coordinate
                            zoomLevel:13
                             animated:NO];
        
        
        //GpsEvent *gpsLocation = [[GpsEvent alloc] init];
        //gpsLocation.coord = location.coordinate;
        //[self locationAvailable:gpsLocation];
        
        //[self.map selectAnnotation:_currentLocation animated:YES];
        
        _hasDoneInitialZoom = YES;
        
    }
     */
}


/*
- (void)changeStyle:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateBegan) {
        NSArray *styles = @[ @"streets", @"emerald", @"light", @"dark", @"satellite" ];
        NSString *currentStyle = [[self.map.styleURL.lastPathComponent componentsSeparatedByString:@"-"] firstObject];
        NSUInteger index = [styles indexOfObject:currentStyle];
        if (index == styles.count - 1) {
            index = 0;
        } else {
            index += 1;
        }
        NSURL *newStyleURL = [[NSURL alloc] initWithString:
                              [NSString stringWithFormat:@"asset://styles/%@-v8.json", styles[index]]];
        self.map.styleURL = newStyleURL;
    }
}
 */


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


- (void)drawMultipolygon:(NSString*)jsonPath restricted:(BOOL)restricted
{
    
    // Perform GeoJSON parsing on a background thread
    dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(backgroundQueue, ^(void){
        
        NSArray *coord;
        CLLocationDegrees lat;
        CLLocationDegrees lng;
        CLLocationCoordinate2D coordinate;
        NSString *featureType;
        NSString *featureName;
        NSArray *featureCoords;
        
        // Load and serialize the GeoJSON into a dictionary filled with properly-typed objects
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[[NSData alloc] initWithContentsOfFile:jsonPath] options:0 error:nil];

        // Load the `features` dictionary for iteration
        for (NSDictionary *feature in jsonDict[@"features"]) {
            NSDictionary *geometry = feature[@"geometry"];
            NSDictionary *properties = feature[@"properties"];
            if (geometry != [NSNull null] && properties != nil){

                featureType = feature[@"geometry"][@"type"];
                featureName = feature[@"properties"][@"NAME"];
                featureCoords = feature[@"geometry"][@"coordinates"];
                
                
                
                if (featureName == nil){
                    featureName = properties[@"PIN"];
                }
                
                if (featureName == nil){
                    featureName = @"unknown";
                } else if (featureName == [NSNull null]){
                    featureName = @"null";
                }
                
                if ([featureName isEqualToString:@"CONDOS"]){
                    NSLog(@"This is the bad one.");
                }
                
                
                if (featureType != nil && featureName != nil && featureCoords != nil){
                    //NSLog(@"Trying to draw object featureType: %@",featureType);
                    // Our GeoJSON only has one feature: a line string
                    if ([featureType isEqualToString:@"MultiPolygon"]){
                        for (NSArray *polygonCoords in featureCoords){
                            for (NSArray *polygonSubCoords in polygonCoords){
                                coord = [polygonSubCoords objectAtIndex:0];
                                lat = [[coord objectAtIndex:1] doubleValue];
                                lng = [[coord objectAtIndex:0] doubleValue];
                                if ([self distanceFromLand:lat lon:lng] < 3000 || !restricted){
                                    
                                    NSLog(@"Drawing feature: %@",featureName);
                                    
                                    [self drawPolygon:featureName coords:polygonSubCoords];
                                }
                            }
                        }
                    } else if ([featureType isEqualToString:@"Polygon"]) {
                        for (NSArray *polygonCoords in featureCoords){
                            coord = [polygonCoords objectAtIndex:0];
                            lat = [[coord objectAtIndex:1] doubleValue];
                            lng = [[coord objectAtIndex:0] doubleValue];
                            if ([self distanceFromLand:lat lon:lng] < 3000 || !restricted){
                                
                                NSLog(@"Drawing feature: %@",featureName);
                                
                                [self drawPolygon:featureName coords:polygonCoords];
                            }
                        }
                    } else {
                        NSLog(@"Unsupported feature type: %@",featureType);
                    }
                } else {
                    NSLog(@"Invalid feature: %@",feature);
                }
                
                
                
            } else {
                NSLog(@"Skipping unrecognized feature: %@",feature);
            }
        }

    });
}

-(double)degreesToRadians:(double)degrees
{
    return degrees * M_PI / 180.0;
}

-(double)distanceFromLand:(double) lat lon:(double)lon
{
    double targetLat = 46.73275;
    double targetLon = -95.81665;
    double dLat = lat - targetLat;
    double dLon = lon - targetLon;
    
    dLat = [self degreesToRadians:dLat];
    dLon = [self degreesToRadians:dLon];
    
    
    double R = 6371000;
    double lat2 = [self degreesToRadians:lat];
    double lat1 = [self degreesToRadians:targetLat];
    
    
    double a = sin(dLat/2) * sin(dLat/2) +
            sin(dLon/2) * sin(dLon/2) *
            cos(lat1) * cos(lat2);
    double c = 2 * atan2(sqrt(a), sqrt(1-a));
    double d = R * c;
    
    //NSLog(@"Distance: %f",d);
    
    return d;
}

-(void)drawPolygon:(NSString*) name coords:(NSArray*)coords
{
    NSUInteger coordinatesCount = coords.count;
    
    // Create a coordinates array, sized to fit all of the coordinates in the line.
    // This array will hold the properly formatted coordinates for our MGLPolyline.
    CLLocationCoordinate2D coordinates[coordinatesCount];
    
    // Iterate over `rawCoordinates` once for each coordinate on the line
    for (NSUInteger index = 0; index < coordinatesCount; index++)
    {
        // Get the individual coordinate for this index
        NSArray *point = [coords objectAtIndex:index];
        
        // GeoJSON is "longitude, latitude" order, but we need the opposite
        CLLocationDegrees lat = [[point objectAtIndex:1] doubleValue];
        CLLocationDegrees lng = [[point objectAtIndex:0] doubleValue];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat, lng);
        
        // Add this formatted coordinate to the final coordinates array at the same index
        coordinates[index] = coordinate;
    }
    
    MGLPolyline *polyline = [MGLPolyline polylineWithCoordinates:coordinates count:coordinatesCount];
    polyline.title = name;
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [weakSelf.map addAnnotation:polyline];
    });
}


-(void)gpsReceiver:(GpsReceiver *)receiver event:(GpsEvent *)event
{
    [self locationAvailable:event];
}

-(void)locationAvailable:(GpsEvent *)location
{
    NSLog(@"Draw location on map: %f, %f",location.coord.latitude,location.coord.longitude);
    
    if (_currentLocation == nil){
        _currentLocation = [[MGLPointAnnotation alloc] init];
    } else {
        [self.map removeAnnotation:_currentLocation];
    }
    
    
    _currentLocation.coordinate = location.coord;
    _currentLocation.title = @"Current Location";
    _currentLocation.subtitle = @"Location from BLE GPS Receiver";
    
    
    [self.map addAnnotation:_currentLocation];
    
    [self.map setCenterCoordinate:location.coord animated:YES];
    
    
}

@end
