//
//  MapController.h
//  Sumy Bus
//
//  Created by Vladimir Smirnov on 9/13/13.
//  Copyright (c) 2013 Vladimir Smirnov. All rights reserved.
//

#import <GoogleMaps/GoogleMaps.h>
#import <UIKit/UIKit.h>

@interface MapController : UIViewController

@property (nonatomic, retain) NSString * routeName;
@property (nonatomic, retain) NSNumber * routeId;

@end
