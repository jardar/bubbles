//
//  AppDelegate.h
//  BubblesOnMac
//
//  Created by 王 得希 on 12-1-9.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WDBubble.h"
#import <Quartz/Quartz.h>

@interface AppDelegate : NSObject <NSApplicationDelegate,QLPreviewPanelDataSource,QLPreviewPanelDelegate>
{
    QLPreviewPanel *_panel;
    NSArray *_array;
}
@property (assign) IBOutlet NSWindow *window;
@property (copy) NSArray *array;
- (IBAction)showPreview:(id)sender;
- (void)showPreviewInHistory;
@end
