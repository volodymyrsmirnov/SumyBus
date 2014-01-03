//
//  AppDelegate.m
//  SumyBus
//
//  Created by Vladimir Smirnov on 9/13/13.
//  Copyright (c) 2013 Vladimir Smirnov. All rights reserved.
//

#import "AppDelegate.h"
#import <GoogleMaps/GoogleMaps.h>
#import "Appirater.h"
#import <YandexMobileMetrica/YandexMobileMetrica.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Google Maps API key
    [GMSServices provideAPIKey:@"AIzaSyCPDFwq5AUeeRX8xpKlUz2Oyaeh9jgggck"];
    
    // Appirater
    [Appirater setAppId:@"705432043"];
    [Appirater setDaysUntilPrompt:1];
    [Appirater setUsesUntilPrompt:5];
    [Appirater setTimeBeforeReminding:2];
    [Appirater appLaunched:YES];
    
    // Yandex.Metrica
    [YMMCounter startWithAPIKey:6280];
    
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [Appirater appEnteredForeground:YES];
}

#pragma mark - CLLocationManagerDelegate Implementation

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [YMMCounter setLocation:newLocation];
}

@end
