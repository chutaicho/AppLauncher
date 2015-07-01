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
    IBOutlet NSTextField* _delayTF;
    IBOutlet NSStepper* _delayStepper;
    IBOutlet NSDatePicker* _datePicker;
    IBOutlet NSButton* _datePickerCheckBox;
	
	NSMutableArray* appList_;
	float _delay;
    BOOL  _keepRunning;
    
    // for END TIMER
    NSCalendar* _calender;
    NSTimer* _timer;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) NSMutableArray* appList;

- (void)timerUpdate;

- (void)onLaunchNotification:(NSNotification *)note;
- (void)onQuitNotification:(NSNotification *)note;
- (BOOL)isOurApplication:(NSString*)appPath;
- (void)launchApp:(NSString*)appName;

- (IBAction)addApplication:(id)sender;
- (IBAction)removeApplication:(id)sender;
- (IBAction)quitApplication:(id)sender;   // shutdown button
- (IBAction)checkBoxHandler:(id)sender;   // _keepRunning
- (IBAction)stepperHandler:(id)sender;    // _delayStepper

- (IBAction)datePickerCheckBoxHandler:(id)sender;
- (IBAction)datePickerHandler:(id)sender; // _datePicker

@end