//
//  MapController.m
//  Sumy Bus
//
//  Created by Vladimir Smirnov on 9/13/13.
//  Copyright (c) 2013 Vladimir Smirnov. All rights reserved.
//

#include <math.h>

#import "MapController.h"
#import "MBProgressHUD.h"
#import "AFNetworking.h"
#import <GoogleMaps/GoogleMaps.h>

@interface MapController ()

@end

@implementation MapController
{
    GMSMapView * mapView;
    NSString * routeName;
    NSInteger routeId;
    
    NSInteger internalRouteId;
    
    MBProgressHUD * progressHUD;
    
    UIImage * stopMarkerIcon;
    UIImage * carMarkerIcon;
    
    bool loadingCars;
    NSTimer * carsTimer;
    
    NSMutableDictionary * routeCars;
}

// initialize map controller with route number
- (id)initWithRouteId:(NSInteger)crouteId routeName:(NSString *)crouteName
{
    self = [super initWithNibName:nil bundle:nil];
    
    routeName = crouteName;
    routeId = crouteId;
    
    return self;
}

// pop to parent view on aler box OK button clicked
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [[self navigationController] popViewControllerAnimated:YES];
}

// show response error
- (void)showResponseError
{
    [progressHUD hide:YES];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Empty server response", nil)
                                                    message:NSLocalizedString(@"This route does not seem to have GPS tracking enabled yet.", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    [alert show];
}

// load route path json
- (void) loadRoutes
{
    GMSMutablePath *routeToPath = [GMSMutablePath path];
    GMSMutablePath *routeFromPath = [GMSMutablePath path];

    progressHUD.detailsLabelText = NSLocalizedString(@"Route Path", nil);
    
    NSURL *routesListURL = [NSURL URLWithString:[[NSString alloc]
                                                 initWithFormat:@"http://sumy.gps-tracker.com.ua/mash.php?act=path&id=%ld&mar=%ld",
                                                 (long)routeId,
                                                 (long)internalRouteId
                                                 ]];
    
    NSURLRequest *routesListRequest = [NSURLRequest requestWithURL:routesListURL];
    
    AFJSONRequestOperation *routesListOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:routesListRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        NSLog(@"Routes list received successfully");
        
        NSArray * loadedRoutes = (NSArray *) JSON;
        
        GMSCoordinateBounds * routeBounds = [[GMSCoordinateBounds alloc] init];
        
        if ([loadedRoutes count] == 0) {
            NSLog(@"Empty routes list");
            [self showResponseError];
        } else {
            for (NSDictionary * routePath in loadedRoutes) {
                CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([[routePath objectForKey:@"lng"] doubleValue], [[routePath objectForKey:@"lat"] doubleValue]);
                
                // add route step coordinate to the route path
                if( [(NSString *)[routePath objectForKey:@"direction"] isEqualToString:@"t"]) {
                    [routeToPath addCoordinate:coord];
                } else {
                    [routeFromPath addCoordinate:coord];
                }
                
                // calculate route camera bounds
                routeBounds = [routeBounds includingCoordinate:coord];
            }
        }
        
        // draw to route
        GMSPolyline * routeToPolyline = [GMSPolyline polylineWithPath:routeToPath];
        [routeToPolyline setStrokeColor:[UIColor colorWithRed:255 green:0 blue:0 alpha:100]];
        [routeToPolyline setStrokeWidth:5.0f];
        [routeToPolyline setMap:mapView];
        
        // draw from route
        GMSPolyline * routeFromPolyline = [GMSPolyline polylineWithPath:routeFromPath];
        [routeFromPolyline setStrokeColor:[UIColor colorWithRed:255 green:0 blue:0 alpha:100]];
        [routeFromPolyline setStrokeWidth:5.0f];
        [routeFromPolyline setMap:mapView];
        
        // center camera position
        [mapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:routeBounds withPadding:10.0f]];
        
        [self loadStops];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
        NSLog(@"Routes list error: %@", error);
        [self showResponseError];
    }];
    
    [routesListOperation start];
}

// load bus stops on the route
- (void) loadStops
{
    progressHUD.detailsLabelText = NSLocalizedString(@"Route Stops", nil);
    
    NSURL *routesStopsURL = [NSURL URLWithString:[[NSString alloc]
                                                 initWithFormat:@"http://sumy.gps-tracker.com.ua/mash.php?act=stops&id=%ld&mar=%ld",
                                                 (long)routeId,
                                                 (long)internalRouteId
                                                 ]];
    
    NSURLRequest *routesStopsRequest = [NSURLRequest requestWithURL:routesStopsURL];
    
    AFJSONRequestOperation *routesStopsOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:routesStopsRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        NSLog(@"Routes stops received successfully");
        
        NSArray * loadedRoutes = (NSArray *) JSON;
                
        if ([loadedRoutes count] == 0) {
            NSLog(@"Empty routes stops");
            [self showResponseError];
        } else {
            for (NSDictionary * routeStop in loadedRoutes) {
                CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([[routeStop objectForKey:@"lng"] doubleValue], [[routeStop objectForKey:@"lat"] doubleValue]);

                // draw stop marker for the bus stop with its name
                GMSMarker * stopMarker = [GMSMarker markerWithPosition:coord];
                [stopMarker setIcon:stopMarkerIcon];
                [stopMarker setTitle:[routeStop objectForKey:@"name"]];
                [stopMarker setZIndex:1];
                [stopMarker setMap:mapView];
            }
        }
        
        // first load for busses
        [self loadCars:nil];
        
        // set timer for executing events
        carsTimer =  [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(loadCars:) userInfo:nil repeats:YES];
                                                
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
        NSLog(@"Routes stops error: %@", error);
        [self showResponseError];
    }];
    
    [routesStopsOperation start];
}

// load buses on routes
- (void) loadCars:(NSTimer *)timer
{
    progressHUD.detailsLabelText = NSLocalizedString(@"Route Buses", nil);
    
    if (loadingCars == NO) {
        loadingCars = YES;
        
        NSURL *routeCarsURL = [NSURL URLWithString:[[NSString alloc]
                                                     initWithFormat:@"http://sumy.gps-tracker.com.ua/mash.php?act=cars&id=%ld",
                                                     (long)routeId
                                                     ]];
        
        NSURLRequest *routeCarsRequest = [NSURLRequest requestWithURL:routeCarsURL];
        
        AFJSONRequestOperation *routeCarsOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:routeCarsRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
        {
            loadingCars = NO;
            
            NSLog(@"Route cars received successfully");
            
            NSArray * loadedCars = [(NSDictionary *) JSON objectForKey:@"rows"];
            
            if ([loadedCars count] == 0) {
                NSLog(@"Empty route cars");
            } else {
                
                NSMutableArray *foundCarIds = [[NSMutableArray alloc] init];
                
                for (NSDictionary * routeCar in loadedCars) {
                    NSInteger carID = [[routeCar objectForKey:@"CarId"] integerValue];
                    
                    [foundCarIds addObject:[NSNumber numberWithInteger:carID]];
                    
                    // skip invalid cars
                    if (
                            ([(NSString *)[routeCar objectForKey:@"inzone" ] isEqualToString:@"f"]) ||
                            ([(NSString *)[routeCar objectForKey:@"color" ] isEqualToString:@"#555555"]) ||
                            ([routeCar objectForKey:@"X"] == [NSNull null] || ([routeCar objectForKey:@"X"] != [NSNull null] && [[routeCar objectForKey:@"X"] integerValue] == 10000)) ||
                            ([routeCar objectForKey:@"Y"] == [NSNull null] || ([routeCar objectForKey:@"X"] != [NSNull null] && [[routeCar objectForKey:@"Y"] integerValue] == 10000)) ||
                            [routeCar objectForKey:@"pX"] == [NSNull null] ||
                            [routeCar objectForKey:@"pY"] == [NSNull null]
                        )
                    {
                        continue;
                    }
                    
                    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([[routeCar objectForKey:@"X"] doubleValue], [[routeCar objectForKey:@"Y"] doubleValue]);
                    
                    GMSGroundOverlay * carMarker;
                    
                    // draw new or update old car marker
                    if ([routeCars objectForKey:[NSNumber numberWithInteger:carID]] == nil) {
                        carMarker = [GMSGroundOverlay groundOverlayWithPosition:coord icon:carMarkerIcon zoomLevel:[[mapView camera] zoom]];
                        [carMarker setZIndex:carID];
                        [carMarker setMap:mapView];
                        [carMarker setTappable:YES];
                        [carMarker setTitle:(NSString *)[routeCar objectForKey:@"CarName"]];
                        
                        [routeCars setObject:carMarker forKey:[NSNumber numberWithInteger:carID]];
                    } else {
                        carMarker = [routeCars objectForKey:[NSNumber numberWithInteger:carID]];
                        [carMarker setPosition:coord];
                    }
                    
                    double carLat = [[routeCar objectForKey:@"X"] doubleValue];
                    double carLng = [[routeCar objectForKey:@"Y"] doubleValue];
                    double carPLat = [[routeCar objectForKey:@"pX"] doubleValue];
                    double carPLng = [[routeCar objectForKey:@"pY"] doubleValue];
                    
                    // calculate and set icon bearing
                    double carAngle = 90 - (atan2(carLat - carPLat, carLng - carPLng) / M_PI) * 180;
                    
                    [carMarker setBearing:carAngle];
                }
                
                // remove old cars from route
                for (NSNumber * prevCarID in routeCars) {
                    if ([foundCarIds indexOfObject:prevCarID] == NSNotFound) {
                        GMSGroundOverlay * carMarker = [routeCars objectForKey:prevCarID];
                        [carMarker setMap:nil];
                        
                        [routeCars removeObjectForKey:prevCarID];
                    }
                }
            }
            
            [progressHUD hide:YES];
      
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
            loadingCars = NO;
            NSLog(@"Routes cars error: %@", error);
        }];
        
        [routeCarsOperation start];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[self navigationItem] setTitle:routeName];
    
    routeCars = [[NSMutableDictionary alloc] init];
    loadingCars = FALSE;
    
    stopMarkerIcon = [UIImage imageNamed:@"stop_icon"];
    carMarkerIcon = [UIImage imageNamed:@"bus_icon"];
	
    // init Google Maps view
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:50.91 longitude:34.800 zoom:12];
    mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    [mapView setDelegate:self];
    
    [mapView setMyLocationEnabled:TRUE];
    
    [[mapView settings] setMyLocationButton:TRUE];
    [[mapView settings] setRotateGestures:FALSE];
    [[mapView settings] setTiltGestures:FALSE];
    
    mapView.accessibilityElementsHidden = NO;
    [self setView:mapView];
    
    progressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progressHUD.labelText = NSLocalizedString(@"Loading", nil);
    progressHUD.detailsLabelText = NSLocalizedString(@"Route Info", nil);
        
    NSURL *routeInfoURL = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"http://sumy.gps-tracker.com.ua/mash.php?act=marw&id=%ld", (long)routeId]];
    NSURLRequest *routeInfoRequest = [NSURLRequest requestWithURL:routeInfoURL];
    
    // allow accepting text/html for JSON type and enable network indicator
    [AFJSONRequestOperation addAcceptableContentTypes:[NSSet setWithObjects:@"text/html", nil]];
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    // get route information
    AFJSONRequestOperation *routeInfoOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:routeInfoRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {        
        if ([(NSArray *) JSON count] == 1) {
            
            NSLog(@"Route information received successfully");
            
            NSDictionary *routeInformation = [(NSArray *) JSON objectAtIndex:0];
            
            if ([routeInformation objectForKey:@"id"]) {
                internalRouteId = [[routeInformation objectForKey:@"id"] integerValue];
                [self loadRoutes];
            }
            else {
                NSLog(@"Route information error, route id key missing");
                [self showResponseError];
            }
        }
        else {
            NSLog(@"Route information error, wrong elements count");
            [self showResponseError];
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
        NSLog(@"Route information error: %@", error);
        [self showResponseError];
    }];
    
    [routeInfoOperation start];
}
@end
