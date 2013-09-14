//
//  AppDelegate.m
//  SumyBus
//
//  Created by Vladimir Smirnov on 9/13/13.
//  Copyright (c) 2013 Vladimir Smirnov. All rights reserved.
//

#import "AppDelegate.h"
#import <GoogleMaps/GoogleMaps.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Google Maps API key
    [GMSServices provideAPIKey:@"AIzaSyCPDFwq5AUeeRX8xpKlUz2Oyaeh9jgggck"];
    
    return YES;
}

@end
