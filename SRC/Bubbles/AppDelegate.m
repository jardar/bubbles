//
//  AppDelegate.m
//  LearnBonjour
//
//  Created by 王 得希 on 12-1-5.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"
#import "PeersViewController.h"

@implementation AppDelegate

@synthesize window = _window, bubble = _bubble;
@synthesize viewController = _viewController, splitViewController = _splitViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    _bubble = [[WDBubble alloc] init];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
        
        ViewController *detailViewController = [[[ViewController alloc] initWithNibName:@"ViewController_iPad" bundle:nil] autorelease];
        UINavigationController *detailNavigationController = [[[UINavigationController alloc] initWithRootViewController:detailViewController] autorelease];
    	detailViewController.bubble = _bubble;
        _bubble.delegate = detailViewController;
        
        PeersViewController *masterViewController = [[[PeersViewController alloc] initWithNibName:@"PeersViewController_iPad" bundle:nil] autorelease];
        UINavigationController *masterNavigationController = [[[UINavigationController alloc] initWithRootViewController:masterViewController] autorelease];
        masterViewController.bubble = detailViewController.bubble;
        
        self.splitViewController = [[[UISplitViewController alloc] init] autorelease];
        self.splitViewController.delegate = detailViewController;
        self.splitViewController.viewControllers = [NSArray arrayWithObjects:masterNavigationController, detailNavigationController, nil];
        
        self.window.rootViewController = self.splitViewController;
        [self.window makeKeyAndVisible];
    } else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
        // Override point for customization after application launch.
        self.viewController = [[[ViewController alloc] initWithNibName:@"ViewController" bundle:nil] autorelease];
        self.viewController.bubble = _bubble;
        _bubble.delegate = self.viewController;
        
        self.window.rootViewController = self.viewController;
        [self.window makeKeyAndVisible];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    [_bubble stopService];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    BOOL usePassword = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsUsePassword];
    if (usePassword) {
        [self.viewController lock];
    } else {
        [_bubble stopService];
        [_bubble publishServiceWithPassword:@""];
        [_bubble browseServices];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    // DW: we do not delete all files now, :-)
    //[self scanDocuments];
}

@end
