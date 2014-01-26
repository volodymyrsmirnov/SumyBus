//
//  RoutesController.m
//  Sumy Bus
//
//  Created by Vladimir Smirnov on 9/13/13.
//  Copyright (c) 2013 Vladimir Smirnov. All rights reserved.
//

#import "RoutesController.h"
#import "MapController.h"
#import "AFNetworking.h"
#import "UIScrollView+SVPullToRefresh.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface RoutesController ()

@end

@implementation RoutesController
{
    NSDictionary *routesList;
    NSMutableDictionary *routesCars;
    NSArray *routesKeys;
    
    BOOL loading;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // parse routes list from plist
    NSString *routesListPath = [[NSBundle mainBundle] pathForResource:@"Routes" ofType:@"plist"];
    routesList = [NSDictionary dictionaryWithContentsOfFile:routesListPath];
    routesKeys = [[routesList allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
    
    routesCars = [[NSMutableDictionary alloc] init];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    [[self tableView] addPullToRefreshWithActionHandler:^{
        [self loadCarsNumber];
    }];
    
    [[[self tableView] pullToRefreshView] setTitle:NSLocalizedString(@"Refresh", nil) forState:SVPullToRefreshStateAll];
    [[[self tableView] pullToRefreshView] setSubtitle:NSLocalizedString(@"Release to refresh", nil) forState:SVPullToRefreshStateTriggered];
    [[[self tableView] pullToRefreshView] setSubtitle:NSLocalizedString(@"Pull to refresh", nil) forState:SVPullToRefreshStateStopped];
    [[[self tableView] pullToRefreshView] setSubtitle:NSLocalizedString(@"Loading", nil) forState:SVPullToRefreshStateLoading];
}

-(void) viewDidAppear: (BOOL) animated
{
    [self loadCarsNumber];
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
    static NSString *cellIdentifier = @"RouteCellCustom";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    NSString *routeKey = [routesKeys objectAtIndex:[indexPath item]];
    NSDictionary *routeDetails = [routesList objectForKey:routeKey];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc]  initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        UIView *carsSubviewContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, 24)];
        
        UIView *carsSubview = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 24, 24)];
        [carsSubview setBackgroundColor:UIColorFromRGB(0xff06a88d)];
        [[carsSubview layer] setCornerRadius:12];
        
        [carsSubviewContainer addSubview:carsSubview];
        [cell setAccessoryView:carsSubviewContainer];

    }
    
    UIView *carsSubview = [[cell accessoryView] subviews][0];
    
    for (UIView *inSubviewView in [carsSubview subviews])
    {
        [inSubviewView removeFromSuperview];
    }
    
    if (loading)
    {
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(6,6,12,12)];
        [spinner setColor:[UIColor whiteColor]];
        [spinner startAnimating];
        
        [carsSubview addSubview:spinner];
    }
    else
    {
        NSNumber *routeID = [routeDetails objectForKey:@"id"];
        
        NSString *carsNumber = @"0";
        
        if ([routesCars objectForKey:routeID] != nil)
        {
            carsNumber = [[routesCars objectForKey:routeID] stringValue];
        }
        
        UILabel *carsNumberLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,0,24,24)];
        [carsNumberLabel setTextColor:[UIColor whiteColor]];
        [carsNumberLabel setTextAlignment:NSTextAlignmentCenter];
        [carsNumberLabel setFont:[UIFont systemFontOfSize:12]];
        [carsNumberLabel setText:carsNumber];
        
        [carsSubview addSubview:carsNumberLabel];
    }
    
    [[cell textLabel] setText:routeKey];
    [[cell detailTextLabel] setText:[routeDetails objectForKey:@"name"]];
    
    return cell;
}

- (void) loadCarsNumber
{
    loading = YES;
    
    [[self tableView] reloadData];
    
    NSURL *routesCarsURL = [NSURL URLWithString:[[NSString alloc]
                                                initWithFormat:@"http://apps.mindcollapse.com/sumy-bus/routes.json?nc=%@",
                                                [[NSProcessInfo processInfo] globallyUniqueString]
                                                ]];
    
    
    NSURLRequest *routesCarsRequest = [NSURLRequest requestWithURL:routesCarsURL];
    
    AFJSONRequestOperation *routesCarsOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:routesCarsRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        NSArray *loadedRoutesCars = (NSArray *) JSON;
        
        routesCars = [[NSMutableDictionary alloc] init];
        
        for (NSObject *routeCars in loadedRoutesCars)
        {
            [routesCars setValue:(NSString *)[routeCars valueForKey:@"cars"] forKey:(NSString *)[routeCars valueForKey:@"id"]];
        }
    
        loading = NO;
        
        [[self tableView] reloadData];
        [[[self tableView] pullToRefreshView] stopAnimating];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
        
        loading = NO;
        
        [[self tableView] reloadData];
        [[[self tableView] pullToRefreshView] stopAnimating];
    }];
    
    [routesCarsOperation start];

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *routeKey = [routesKeys objectAtIndex:[indexPath item]];
    NSDictionary *routeDetails = [routesList objectForKey:routeKey];
    
    MapController *routeView = [[self storyboard] instantiateViewControllerWithIdentifier:@"Map"];
    
    [routeView setRouteName:[routeDetails objectForKey:@"name"]];
    [routeView setRouteId:[NSNumber numberWithInteger:[[routeDetails objectForKey:@"id"] integerValue]]];
    
    [[self navigationController] pushViewController:routeView animated:YES];
}

@end
