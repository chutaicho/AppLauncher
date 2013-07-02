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

@implementation AppLauncherAppDelegate

@synthesize window;
@synthesize appList = appList_;

- (id) init
{
	self = [super init];
	if (self != nil) {
		self.appList = [NSMutableArray array];
		
		//[NSCursor hide];
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
	
//	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
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
	//NSLog(@"applicationDidFinishLaunching start");
	// Insert code here to initialize your application
	NSUserDefaults* userDefaults = [[NSUserDefaultsController sharedUserDefaultsController] values];
	
	_delay = ([userDefaults valueForKey:UDKEY_CALLBACK_DELAY] != nil)? [[userDefaults valueForKey:UDKEY_CALLBACK_DELAY] floatValue] : 0.5f;
	[_delayTF setFloatValue:_delay];
	[_delaySlider setFloatValue:_delay];
	
	if([userDefaults valueForKey:UDKEY_HELPER_APPLICATION_LIST] != nil)
	{
		NSArray* pathList = [userDefaults valueForKey:UDKEY_HELPER_APPLICATION_LIST];
		
		for (NSString* path in pathList) 
		{
			[appList_ addObject:[[[ApplicationEntry alloc] initWithPath:path] autorelease]];
		}		
	}
	
	[arrayController_ rearrangeObjects];
	[tableView_ registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, AppListTableViewDataType, nil]];
	[tableColumn_ setDataCell:[[[ApplicationCell alloc] init] autorelease]];
	
//	NSButtonCell* cell = [ [ [ NSButtonCell alloc ] initTextCell: @"" ] autorelease ];
//	[ cell setEditable: YES ]; 
//	[ cell setButtonType: NSSwitchButton ]; 
//	[ tableColumn_ setDataCell: cell ];
	
	
	NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];
	[nc addObserver:self selector:@selector(onLaunchNotification:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
	[nc addObserver:self selector:@selector(onQuitNotification:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	
	if([appList_ count] > 0)
	{
		for (ApplicationEntry *app in appList_)
		[[NSWorkspace sharedWorkspace] launchApplication:app.path];
	}
	
	//[NSMenu setMenuBarVisible : NO];
	//NSLog(@"applicationDidFinishLaunching end");
}

#pragma mark -
#pragma mark NSNotification Handler

- (void)onLaunchNotification:(NSNotification *)note
{	
	//NSLog(@"onLaunchNotification");
}
- (void)onQuitNotification:(NSNotification *)note
{
	NSDictionary* dicApp = [note userInfo];
	//NSString* sName = [dicApp objectForKey : @"NSApplicationName"];
	NSString* sPath = [dicApp objectForKey : @"NSApplicationPath"];
	
	//NSLog(@"onQuitNotification %@, path : %@", sName, sPath);
	
	if([self isOurApplication:sPath])
	{
		//NSLog(@"isOurApplication YES, launchApplication :  %@, path : %@", sName, sPath);
		[self performSelector:@selector(launchApp:) withObject:sPath afterDelay:_delay];		
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
	[openPanel setDirectory:path];
	
	int result = [openPanel runModalForDirectory:path file:nil types:nil];
	
	if (result == NSOKButton) {
		for (NSString* filename in [openPanel filenames]) {
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
	//NSLog(@"removeApplication, %i", [appList_ count]);
	
	if([appList_ count] > 0)
	{
		[arrayController_ removeObjectAtArrangedObjectIndex:[arrayController_ selectionIndex]];
		[self rearrangeList];
	}
}
- (IBAction)quitApplication:(id)sender
{
	//NSLog(@"quitApplication");
	[NSApp terminate:self];
}
- (IBAction)onSliderChange:(id)sender
{
	//NSLog(@"onSliderChange");
	_delay = [(NSSlider*)sender floatValue];
	
	[_delayTF setFloatValue:_delay];
	[_delaySlider setFloatValue:_delay];
	
	NSUserDefaults* userDefaults = [[NSUserDefaultsController sharedUserDefaultsController] values];
	[userDefaults setValue:[NSNumber numberWithFloat:_delay] forKey:UDKEY_CALLBACK_DELAY];
}
//- (IBAction)menuVisible:(id)sender
//{
//	BOOL status = [NSMenu menuBarVisible];
//	[NSMenu setMenuBarVisible : !status];
//}

/*
 - (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
 {
 if (returnCode == NSOKButton) {
 for (NSString* filename in [panel filenames]) {
 ApplicationEntry* entry = [[[ApplicationEntry alloc] initWithPath:filename] autorelease];
 
 [appList_ addObject:entry];
 }
 [arrayController_ rearrangeObjects];
 }
 }
 */

#pragma mark -
#pragma mark NSTableViewDataSource Protocol

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	//NSLog(@"drag starts");

	// Copy the row numbers to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:AppListTableViewDataType] owner:self];
    [pboard setData:data forType:AppListTableViewDataType];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	[aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
	
	if ([info draggingSource] == tableView_) {
		return NSDragOperationMove;
	} 
	return NSDragOperationEvery;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard* pboard = [info draggingPasteboard];	
	NSArray* pboardTypes = [pboard types];
	
	if ([pboardTypes containsObject:AppListTableViewDataType]) {
		
		NSData* data = [pboard dataForType:AppListTableViewDataType];
		
		NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		
		NSArray* srcArray = [appList_ objectsAtIndexes:rowIndexes];
		NSUInteger srcCount = [srcArray count];
		
		if ([rowIndexes firstIndex] < row) {
			row = row - srcCount;
		}
		NSIndexSet* newIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, srcCount)];
		
		[appList_ removeObjectsAtIndexes:rowIndexes];
		[appList_ insertObjects:srcArray atIndexes:newIndexes];
		[self rearrangeList];
		
		
//		[arrayController_ removeObjectsAtArrangedObjectIndexes:rowIndexes];
//		[arrayController_ insertObjects:srcArray atArrangedObjectIndexes:newIndexes];
		return YES;
		
	} else if ([pboardTypes containsObject:NSFilenamesPboardType]) {
		NSArray*filenames = [pboard propertyListForType:NSFilenamesPboardType];
		
		for (NSString* filename in filenames) {
			ApplicationEntry* entry = [[[ApplicationEntry alloc] initWithPath:filename] autorelease];
			
			[appList_ insertObject:entry atIndex:row];
//			[arrayController_ insertObject:entry atArrangedObjectIndex:row];
		}
		[self rearrangeList];
		return YES;
	} else {
		return NO;
	}
}

@end
