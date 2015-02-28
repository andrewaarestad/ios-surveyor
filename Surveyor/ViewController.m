//
//  ViewController.m
//  Surveyor
//
//  Created by Andrew on 2/27/15.
//  Copyright (c) 2015 AAE. All rights reserved.
//

#import "ViewController.h"

#import "Mapbox.h"
#import "GpsInterface.h"

#define kMapboxMapID @"gathius.lb5ncnhg"

@interface ViewController () <GpsInterfaceObserver>

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    RMMapboxSource *onlineSource = [[RMMapboxSource alloc] initWithMapID:kMapboxMapID];
    
    RMMapView *mapView = [[RMMapView alloc] initWithFrame:self.view.bounds andTilesource:onlineSource];
    
    
    mapView.zoom = 15;
    
    CLLocationCoordinate2D startLocation = { 46.733454, -95.818355 };
    
    [mapView setCenterCoordinate:startLocation];
    
    mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    [self.view addSubview:mapView];
    
    [GpsInterface addObserver:self];
}

-(void)viewDidAppear:(BOOL)animated
{
    [GpsInterface addObserver:self];
}
-(void)viewWillDisappear:(BOOL)animated
{
    [GpsInterface removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


-(void)locationAvailable:(GpsLocation *)location
{
    NSLog(@"Draw location on map: %@",location);
}

@end
