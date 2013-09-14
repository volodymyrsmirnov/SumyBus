//
//  RoutesController.m
//  Sumy Bus
//
//  Created by Vladimir Smirnov on 9/13/13.
//  Copyright (c) 2013 Vladimir Smirnov. All rights reserved.
//

#import "RoutesController.h"
#import "MapController.h"

@interface RoutesController ()

@end

@implementation RoutesController
{
    NSDictionary * routesList;
    NSArray * routesKeys;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // parse routes list from plist
    NSString *routesListPath = [[NSBundle mainBundle] pathForResource:@"Routes" ofType:@"plist"];
    routesList = [NSDictionary dictionaryWithContentsOfFile:routesListPath];
    routesKeys = [[routesList allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [routesList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"RouteCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    NSString * routeKey = [routesKeys objectAtIndex:[indexPath item]];
    NSDictionary * routeDetails = [routesList objectForKey:routeKey];
        
    cell.textLabel.text = routeKey;
    cell.detailTextLabel.text = [routeDetails objectForKey:@"name"];
        
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * routeKey = [routesKeys objectAtIndex:[indexPath item]];
    NSDictionary * routeDetails = [routesList objectForKey:routeKey];
    
    NSInteger routeID = [[routeDetails objectForKey:@"id"] integerValue];
    
    MapController *routeView = [[MapController alloc] initWithRouteId:routeID routeName:[routeDetails objectForKey:@"name"]];
    [[self navigationController] pushViewController:routeView animated:YES];
}

@end
