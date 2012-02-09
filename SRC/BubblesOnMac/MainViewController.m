//
//  MainViewController.m
//  Bubbles
//
//  Created by 吴 wuziqi on 12-1-11.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "MainViewController.h"
@implementation MainViewController
@synthesize fileURL = _fileURL;
@synthesize bubble = _bubble;

#pragma mark - Private Methods

- (void)loadUserPreference
{
    if (_passwordController != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"NSWindowDidBecomeKeyNotification"];
        return ;
    }
    
    bool status = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsUsePassword];
    
    if (status) {
        _passwordController = [[PasswordMacViewController alloc]init];
        _passwordController.delegate = self;
        
        [NSApp beginSheet:[_passwordController window] modalForWindow:[NSApplication sharedApplication].mainWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
        
    } else {
        [_bubble publishServiceWithPassword:@""];
        [_bubble browseServices];
    }
}

- (void)delayNotification {
    [self performSelector:@selector(loadUserPreference) withObject:nil afterDelay:1.0f];
}

// DW: we do not need this method now
/*- (void)directlySave {
    NSURL *url = [[NSUserDefaults standardUserDefaults] URLForKey:kUserDefaultMacSavingPath];
    if (_fileURL && _imageMessage.image != nil) {
        NSFileManager *manager = [NSFileManager defaultManager];
        
        NSString *fileExtension = [[_fileURL absoluteString] pathExtension];
        NSString *filename = [NSString stringWithFormat:@"%@.%@",[NSDate date],fileExtension];
        DLog(@"filename is %@!!!!!!!",filename);
        
        NSData *data = [NSData dataWithContentsOfURL:_fileURL];
        
        NSString *fullPath = [[url path] stringByAppendingPathComponent:filename];
        [manager createFileAtPath:fullPath contents:data attributes:nil];
    }
}*/

- (void)storeMessage:(WDMessage *)message
{
    DLog(@"storeMessage");
    [_historyPopOverController.fileHistoryArray addObject:message];
   /* [_fileHistoryArray sortUsingComparator:^(WDMessage *obj1, WDMessage * obj2) {
        if ([obj1.time compare:obj2.time] == NSOrderedAscending)
            return NSOrderedDescending;
        else if ([obj1.time compare:obj2.time] == NSOrderedDescending)
            return NSOrderedAscending;
        else
            return NSOrderedSame;
    }];*/
    [_historyPopOverController.filehistoryTableView reloadData];
}


#pragma mark - init & dealloc

- (id)init
{
    if (self = [super init]) {
        // Wu: init bubbles
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:@"file://localhost/~/Downloads/" forKey:kUserDefaultMacSavingPath]];
        
        _bubble = [[WDBubble alloc] init];
        _bubble.delegate = self;
    
        //Wu:the initilization is open the send text view;
        _isView = kTextViewController;
    }
    return self;
}

- (void)dealloc
{
    // Wu:Remove observe the notification
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"NSWindowDidBecomeKeyNotification"];
    
    // Wu:Remove two subviews
    [[_textViewController view] removeFromSuperview];
    [[_dragFileController view] removeFromSuperview];
    [_superView release];
    [_dragFileController release];
    [_textViewController release];
    
    // Wu:Release two window controller
    [_passwordController release];
    [_preferenceController release];
       
    [_bubble release];
    [_fileURL release];
    [_checkBox release];
    [_swapButton release];
    [super dealloc];
}

- (void)awakeFromNib
{
    bool status = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsUsePassword];
    [_checkBox setState:status];
    // Wu:Add observer to get the notification when the main menu become key window then the sheet window will appear
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(delayNotification)
                                                 name:@"NSWindowDidBecomeKeyNotification" object:nil];

    // Wu: Alloc the two view controller and first add textviewcontroller into superview
    _textViewController = [[TextViewController alloc]initWithNibName:@"TextViewController" bundle:nil];
    _dragFileController = [[DragFileViewController alloc]initWithNibName:@"DragFileViewController" bundle:nil];
    
    [[_textViewController view] setFrame:[_superView bounds]];
    [[_dragFileController view] setFrame:[_superView bounds]];
    
    [_superView addSubview:[_textViewController view]];
    [_superView addSubview:[_dragFileController view]];
    
    _dragFileController.imageView.delegate = self;
   
    
    // Wu:Hide some buttons with related to Drag File
    [_dragFileController.view setHidden:YES];
    [_selectFile setHidden:YES];
    [_sendFile setHidden:YES];
    
    // Wu:Init two popover
    _historyPopOverController = [[HistoryPopOverViewController alloc]
                                 initWithNibName:@"HistoryPopOverViewController" bundle:nil];
    
    _networkPopOverController = [[NetworkFoundPopOverViewController alloc]
                                 initWithNibName:@"NetworkFoundPopOverViewController" bundle:nil];
    _networkPopOverController.bubble = self.bubble;
}

#pragma mark - IBActions

- (IBAction)sendText:(id)sender {
    DLog(@"MVC sendText %@", _textViewController.textField.stringValue);
    if (_isView == kTextViewController) {
        [_bubble broadcastMessage:[WDMessage messageWithText:_textViewController.textField.stringValue]];
    }
}

- (IBAction)togglePassword:(id)sender {
    NSButton *button = (NSButton *)sender;
    [[NSUserDefaults standardUserDefaults] setBool:button.state forKey:kUserDefaultsUsePassword];
    
    if (button.state == NSOnState) {
        // DW: user turned password on.
        if (_passwordController == nil) {
            _passwordController = [[PasswordMacViewController alloc]init];
            _passwordController.delegate = self;
        }
        
        // Wu: show as a sheet window to force users to set usable password
        [NSApp beginSheet:[_passwordController window] modalForWindow:[NSApplication sharedApplication].keyWindow  modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
        
    } else {
        [_bubble stopService];
        [_bubble publishServiceWithPassword:@""];
        [_bubble browseServices];
    }
}

- (IBAction)selectFile:(id)sender
{
    if (_isView == kTextViewController) {
        return ;
    }
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

	[openPanel setTitle:@"Choose File"];
	[openPanel setPrompt:@"Browse"];
	[openPanel setNameFieldLabel:@"Choose a file:"];
    
    if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
        _fileURL = [[openPanel URL] retain];//the path of your selected photo
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:_fileURL];
        if (image != nil) {
            [_dragFileController.imageView setImage:image];
            [image release];   
        }else {
            NSImage *quicklook = [NSImage imageWithPreviewOfFileAtPath:[_fileURL path] asIcon:YES];
            [_dragFileController.imageView setImage:quicklook];
        }
    }
}

- (IBAction)sendFile:(id)sender {
    if (_isView == kTextViewController) {
        return ;
    }
     WDMessage *t = [[WDMessage messageWithFile:_fileURL] retain];
    [self storeMessage:t];
    [_bubble broadcastMessage:t];
    [t release];
}

- (IBAction)showPreferencePanel:(id)sender
{
    if (_preferenceController == nil) {
        _preferenceController = [[PreferenceViewContoller alloc]init];
    }
    
    [_preferenceController showWindow:self];
}

- (IBAction)deleteSelectedRows:(id)sender
{
    if ([_historyPopOverController.filehistoryTableView selectedRow] < 0 || 
        [_historyPopOverController.filehistoryTableView selectedRow] >= [_historyPopOverController.fileHistoryArray count])
    {
        return ;
    } else {
        [_historyPopOverController.fileHistoryArray removeObjectAtIndex:
                                                    [_historyPopOverController.filehistoryTableView selectedRow]];
        
        [_historyPopOverController.filehistoryTableView noteNumberOfRowsChanged];
        [_historyPopOverController.filehistoryTableView reloadData];
    }
}

- (IBAction)removeAllHistory:(id)sender
{
    if ([_historyPopOverController.fileHistoryArray count] == 0) {
        return ;
    } else {
        [_historyPopOverController.fileHistoryArray removeAllObjects];
        [_historyPopOverController.filehistoryTableView noteNumberOfRowsChanged];
        [_historyPopOverController.filehistoryTableView reloadData];
    }
}

- (IBAction)swapView:(id)sender
{
    if (_isView == kTextViewController) {
        _isView = kDragFileController;
        [_textViewController.view setHidden:YES withFade:YES];
        [_dragFileController.view setHidden:NO withFade:YES];
        [_sendText setHidden:YES];
        [_sendFile setHidden:NO];
        [_selectFile setHidden:NO];
        _swapButton.title = @"Swap to Messages";
        
    } else {
        _isView = kTextViewController;
        [_textViewController.view setHidden:NO withFade:YES];
        [_dragFileController.view setHidden:YES withFade:YES];
        [_sendFile setHidden:YES];
        [_selectFile setHidden:YES];
        [_sendText setHidden:NO];
        _swapButton.title = @"Swap to Files";
    }
}

- (IBAction)openHistoryPopOver:(id)sender
{
    NSButton *button = (NSButton *)sender;
   
    [_historyPopOverController showHistoryPopOver:button];
    
}

- (IBAction)openServiceFoundPopOver:(id)sender
{
    NSButton *button = (NSButton *)sender;
    [_networkPopOverController showServicesFoundPopOver:button];
}

#pragma mark - WDBubbleDelegate

- (void)didReceiveMessage:(WDMessage *)message ofText:(NSString *)text {
    DLog(@"VC didReceiveText %@", text);
    if (_isView == kTextViewController) {
        _textViewController.textField.stringValue = text;
        [self storeMessage:message];
    } 
}

- (void)didReceiveMessage:(WDMessage *)message ofFile:(NSURL *)url {
    DLog(@"MVC didReceiveFile %@", url);
    if (_isView != kDragFileController) {
        return ;
    }
    [self storeMessage:message];
    
    // DW: store this url for drag and drop
    if (_fileURL) {
        [_fileURL release];
    }
    _fileURL = [url retain];
   
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
    if (image != nil) {
        [_dragFileController.imageView setImage:image];
        [image release];
    } else {
        NSImage *quicklook = [NSImage imageWithPreviewOfFileAtPath:[url path] asIcon:YES];
        [_dragFileController.imageView setImage:quicklook];
    }
}

#pragma mark - PasswordMacViewControllerDelegate

- (void)didCancel {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserDefaultsUsePassword];
    _checkBox.state = NSOffState;
}

- (void)didInputPassword:(NSString *)pwd {
    [_bubble stopService];
    [_bubble publishServiceWithPassword:pwd];
    [_bubble browseServices];
}

#pragma mark - DragAndDropImageViewDelegate

- (void)dragDidFinished:(NSURL *)url
{
    DLog(@"dragDidFinished");
    if (_fileURL) {
        [_fileURL release];
    }
    _fileURL = [url retain];
}

- (NSURL *)dataDraggedToSave
{
    if (_isView == kTextViewController) {
        return nil;
    } else if (_fileURL && _dragFileController.imageView.image != nil) {
        return _fileURL;
    }
    return nil;
}


@end
