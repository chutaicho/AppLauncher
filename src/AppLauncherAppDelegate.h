//
//  AppLauncherAppDelegate.h
//  AppLauncher
//
//  Created by Takashi Aoki on 12/02/23.
//  (c)takashiaoki.com
//

#import <Cocoa/Cocoa.h>

@interface AppLauncherAppDelegate : NSObject <NSApplicationDelegate> 
{	
	NSWindow *window;
	
	IBOutlet NSTableView* tableView_;
	IBOutlet NSArrayController* arrayController_;
	IBOutlet NSTableColumn* tableColumn_;
	IBOutlet NSSlider* _delaySlider;
	IBOutlet NSTextField* _delayTF;
	
	NSMutableArray* appList_;
	float _delay;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) NSMutableArray* appList;

- (void)onLaunchNotification:(NSNotification *)note;
- (void)onQuitNotification:(NSNotification *)note;
- (BOOL)isOurApplication:(NSString*)appPath;
- (void)launchApp:(NSString*)appName;

- (IBAction)addApplication:(id)sender;
- (IBAction)removeApplication:(id)sender;
- (IBAction)quitApplication:(id)sender;
- (IBAction)onSliderChange:(id)sender;
//- (IBAction)menuVisible:(id)sender;

@end
