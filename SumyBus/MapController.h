//
//  MapController.h
//  Sumy Bus
//
//  Created by Vladimir Smirnov on 9/13/13.
//  Copyright (c) 2013 Vladimir Smirnov. All rights reserved.
//

#import <GoogleMaps/GoogleMaps.h>
#import <UIKit/UIKit.h>

@interface MapController : UIViewController <GMSMapViewDelegate>

- (void)showResponseError;

- (void) loadRoutes;
- (void) loadStops;
- (void) loadCars:(NSTimer *)timer;

- (id)initWithRouteId:(NSInteger)crouteId routeName:(NSString *)crouteName;

@end
