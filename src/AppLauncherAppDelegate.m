//
//  AppLauncherAppDelegate.h
//  AppLauncher
//
//  Created by Takashi Aoki on 12/02/23.
//  (c)takashiaoki.com
//

#import "AppLauncherAppDelegate.h"

#import "ApplicationEntry.h"
#import "ApplicationCell.h"
#define AppListTableViewDataType        @"AppListTableViewDataType"
#define UDKEY_HELPER_APPLICATION_LIST	@"HelperApplicationList"
#define UDKEY_CALLBACK_DELAY	        @"CallBackDelayTime"
#define UDKEY_END_TIMER_STATUS	        @"EndTimerStatus"
#define UDKEY_END_TIME	                @"EndTime"

@implementation AppLauncherAppDelegate

@synthesize window;
@synthesize appList = appList_;

- (id) init
{
	self = [super init];
	if (self != nil) {
		self.appList = [NSMutableArray array];
	}
	return self;
}
- (void) dealloc
{
	self.appList = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark Utilities

- (void)rearrangeList
{
	[arrayController_ rearrangeObjects];
	
	NSUserDefaults* userDefaults = [[NSUserDefaultsController sharedUserDefaultsController] values];
	NSMutableArray* pathList = [NSMutableArray array];
	
	for (ApplicationEntry* entry in appList_)
	{
		[pathList addObject:entry.path];
	}
	
	[userDefaults setValue:pathList forKey:UDKEY_HELPER_APPLICATION_LIST];
}

#pragma mark -
#pragma mark Application Delegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
    _keepRunning = YES;
    
	// Insert code here to initialize your application
	NSUserDefaults* userDefaults = [[NSUserDefaultsController sharedUserDefaultsController] values];
	
	_delay = ([userDefaults valueForKey:UDKEY_CALLBACK_DELAY] != nil)? [[userDefaults valueForKey:UDKEY_CALLBACK_DELAY] floatValue] : 1.0f;
	[_delayTF setFloatValue:_delay];
    [_delayStepper setFloatValue:_delay];
    
    if([userDefaults valueForKey:UDKEY_END_TIME] != nil)
    {
        NSDate* endtime = [userDefaults valueForKey:UDKEY_END_TIME];
        [_datePicker setDateValue:endtime];
    }
    if([userDefaults valueForKey:UDKEY_END_TIMER_STATUS] != nil)
    {
        NSNumber* timerStatus = [userDefaults valueForKey:UDKEY_END_TIMER_STATUS];
        [_datePickerCheckBox setState:[timerStatus intValue]];
        [_datePicker setEnabled:([timerStatus intValue] == 0)? NO : YES];
    }
	if([userDefaults valueForKey:UDKEY_HELPER_APPLICATION_LIST] != nil)
	{
		NSArray* pathList = [userDefaults valueForKey:UDKEY_HELPER_APPLICATION_LIST];
        
		for (NSString* path in pathList)[appList_ addObject:[[[ApplicationEntry alloc] initWithPath:path] autorelease]];
	}
	
	[arrayController_ rearrangeObjects];
	[tableView_ registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, AppListTableViewDataType, nil]];
	[tableColumn_ setDataCell:[[[ApplicationCell alloc] init] autorelease]];
	
	NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];
    //[nc addObserver:self selector:@selector(onLaunchNotification:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
	[nc addObserver:self selector:@selector(onQuitNotification:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	
	if([appList_ count] > 0)
	{
        int i = 1;
        for (ApplicationEntry *app in appList_)
        {
            [self performSelector:@selector(launchApp:) withObject:app.path afterDelay:_delay*i++];
        }
	}
    
    // Create Timer Objects...
    _calender = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [_calender retain];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(timerUpdate) userInfo:nil repeats:YES];
}
#pragma mark -
#pragma mark timer handler

- (void)timerUpdate
{
    if([_datePickerCheckBox state] == NSOnState)
    {
        NSDate* now = [NSDate date];
        NSDateComponents* dateComponents = [_calender components:(NSHourCalendarUnit  | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:now];
        NSInteger hour = [dateComponents hour];
        NSInteger minute = [dateComponents minute];
        NSInteger second = [dateComponents second];
        
        NSDate* target = [_datePicker dateValue];
        dateComponents = [_calender components:(NSHourCalendarUnit  | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:target];
        NSInteger t_hour   = [dateComponents hour];
        NSInteger t_minute = [dateComponents minute];
        //NSInteger t_second = [dateComponents second];
        
//        NSLog(@"---------------");
//        NSLog(@"NOW - %ld : %ld : %ld",(long)hour,(long)minute,(long)second);
//        NSLog(@"END - %ld : %ld : %ld",(long)t_hour,(long)t_minute,(long)t_second);

        if(hour == t_hour && minute == t_minute)
        {
            if(second > 0)
            {
                if([_timer isValid])[_timer invalidate];
                [self quitApplication:nil];
            }
        }
    }
}

#pragma mark -
#pragma mark NSNotification Handler

- (void)onLaunchNotification:(NSNotification *)note
{
    // hide applications except index 0;
    NSDictionary* dicApp = [note userInfo];
	NSString* sName = [dicApp objectForKey : @"NSApplicationName"];
	NSString* sPath = [dicApp objectForKey : @"NSApplicationPath"];
    
    
    ApplicationEntry *activeApp = [appList_ objectAtIndex:0];
    if([sPath compare:activeApp.path] != NSOrderedSame)
    {
        NSString* scp1 = @"tell application \"System Events\" to tell process \"";
        NSString* scp2 = @"\" to set visible to false";
//        NSString* scp1 = @"tell application \"System Events\" to tell process \"";
//        NSString* scp2 = @"\" to keystroke \"h\" using command down";
        NSString* message =[NSString stringWithFormat:@"%@%@%@",scp1,sName,scp2];
        NSAppleScript * script = [[NSAppleScript alloc] initWithSource:message];
        [script executeAndReturnError:nil];
        [script release];
    }
}
- (void)onQuitNotification:(NSNotification *)note
{
	NSDictionary* dicApp = [note userInfo];
	NSString* sPath = [dicApp objectForKey : @"NSApplicationPath"];
	
	if([self isOurApplication:sPath])
	{
        float delay = (_keepRunning)? 1.0 : _delay;
		[self performSelector:@selector(launchApp:) withObject:sPath afterDelay:delay];
	}
}
- (void)launchApp:(NSString*)appName
{
	[[NSWorkspace sharedWorkspace] launchApplication:appName];
    //NSLog(@"launchApplicatoin %@", appName);
}
- (BOOL)isOurApplication:(NSString*)appPath
{
	for (ApplicationEntry *app in appList_)
	{
		//NSLog(@"appList_ %@", app.path);
		if ([appPath isEqual:app.path]){
			return YES;
		}
	}
	return NO;
}

#pragma mark -
#pragma mark Accssors

- (IBAction)addApplication:(id)sender
{
    NSString* path = @"/Applications";
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanCreateDirectories:NO];
	[openPanel setAllowsMultipleSelection:YES];

    // deprecated in 10.6
//    [openPanel setDirectory:path];
//    int result = [openPanel runModalForDirectory:path file:nil types:nil];
    
    [openPanel setDirectoryURL:[NSURL URLWithString:path]];
    int result = [openPanel runModal];
	if (result == NSOKButton)
    {
//		for (NSString* filename in [openPanel filenames]) // deprecated in 10.6
		for (NSString* filename in [openPanel URLs])
        {
			ApplicationEntry* entry = [[[ApplicationEntry alloc] initWithPath:filename] autorelease];
			[appList_ addObject:entry];
		}
		[self rearrangeList];
	}
	
	/*/
	[openPanel beginSheetForDirectory:path file:nil types:nil modalForWindow:window modalDelegate:self
	didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
	//*/
}
- (IBAction)removeApplication:(id)sender
{
	if([appList_ count] > 0)
	{
		[arrayController_ removeObjectAtArrangedObjectIndex:[arrayController_ selectionIndex]];
		[self rearrangeList];
	}
}
- (IBAction)quitApplication:(id)sender
{
    for (ApplicationEntry* app in appList_)
    {
        NSString* message =[NSString stringWithFormat:@"quit app \"%@\"",app.path];
        NSAppleScript * script = [[NSAppleScript alloc] initWithSource:message];
        [script executeAndReturnError:nil];
        [script release];
    }

    [NSThread sleepForTimeInterval:0.25];
    [NSApp terminate:self];
}
- (IBAction)stepperHandler:(id)sender
{
    _delay = [(NSSlider*)sender floatValue];
    [_delayTF setFloatValue:_delay];
    
    NSUserDefaults* userDefaults = [[NSUserDefaultsController sharedUserDefaultsController] values];
    [userDefaults setValue:[NSNumber numberWithFloat:_delay] forKey:UDKEY_CALLBACK_DELAY];
    //NSLog(@"stepper: %ld", value);
}
- (IBAction)checkBoxHandler:(id)sender
{
    _keepRunning = ([(NSButton*)sender state] == NSOnState)? YES : NO;
}
- (IBAction)datePickerCheckBoxHandler:(id)sender
{
    BOOL status = ([(NSButton*)sender state] == NSOnState)? YES : NO;
    [_datePicker setEnabled:status];
    
    NSUserDefaults* userDefaults = [[NSUserDefaultsController sharedUserDefaultsController] values];
    [userDefaults setValue:[NSNumber numberWithInt:((status)? 1 : 0)] forKey:UDKEY_END_TIMER_STATUS];
}
- (IBAction)datePickerHandler:(id)sender
{
    NSDate* d = [_datePicker dateValue];
    NSUserDefaults* userDefaults = [[NSUserDefaultsController sharedUserDefaultsController] values];
    [userDefaults setValue:d forKey:UDKEY_END_TIME];
}

#pragma mark -
#pragma mark NSTableViewDataSource Protocol

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	// Copy the row numbers to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:AppListTableViewDataType] owner:self];
    [pboard setData:data forType:AppListTableViewDataType];
    return YES;
}
- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	[aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
	
	if ([info draggingSource] == tableView_)
    {
		return NSDragOperationMove;
	} 
	return NSDragOperationEvery;
}
- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard* pboard = [info draggingPasteboard];	
	NSArray* pboardTypes = [pboard types];
	
	if([pboardTypes containsObject:AppListTableViewDataType])
    {
		NSData* data = [pboard dataForType:AppListTableViewDataType];
		NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		
		NSArray* srcArray = [appList_ objectsAtIndexes:rowIndexes];
		NSUInteger srcCount = [srcArray count];
		
		if ([rowIndexes firstIndex] < row)
        {
			row = row - srcCount;
		}
        
		NSIndexSet* newIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, srcCount)];
		[appList_ removeObjectsAtIndexes:rowIndexes];
		[appList_ insertObjects:srcArray atIndexes:newIndexes];
		[self rearrangeList];
		
//		[arrayController_ removeObjectsAtArrangedObjectIndexes:rowIndexes];
//		[arrayController_ insertObjects:srcArray atArrangedObjectIndexes:newIndexes];
		return YES;
		
	}
    else if ([pboardTypes containsObject:NSFilenamesPboardType])
    {
		NSArray*filenames = [pboard propertyListForType:NSFilenamesPboardType];
		
		for (NSString* filename in filenames)
        {
			ApplicationEntry* entry = [[[ApplicationEntry alloc] initWithPath:filename] autorelease];
			[appList_ insertObject:entry atIndex:row];
//			[arrayController_ insertObject:entry atArrangedObjectIndex:row];
		}
        
		[self rearrangeList];
		return YES;
	}
    else
    {
        return NO;
	}
}

@end
