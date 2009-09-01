/* 
RemberController.h
 
RemberController class definition.
 
 Controls program interaction between TaskWrapper and Interface
 
Copyright (C) 2004  Eddie Kelley <eddie@kelleycomputing.net>

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 
 Version History:
	0.1b Initial Public Beta
	0.1.04b Updated version online with newer memtest 4.0.4M
		¥ Memtest 4.0.4M executable included
		¥ Switched to spinning progress indicator (for better performance)
	0.2.0b
		¥ Total GUI overhaul.  
		¥ Preferences added.  
		¥ Verbose logging (filtering) function added
		¥ Test progress in status field
		¥ Loop counter
		¥ Application/Finder quit functions
	0.2.1b
		¥ Preferences window is now a sheet
		¥ Save option for log details
		¥ Dock menu
		¥ Icon added 
	0.2.2b
		¥ Performance enahncements
		¥ Icon touch-up
	0.2.3b
		¥ Uses new version of memtest executable (4.05M)
	0.3b
		¥ Uses new version of memtest executable (4.11)
		¥ Added "Continue on Error" preference
	0.3.1b
		¥ Uses new version of memtest executable (4.12)
		¥ Utilizes User Defaults system to save preferences
	0.3.2b
		¥ Uses new version of memtest executable (4.13)
		¥ Universal Binary
	0.3.3b
		¥ Now displays determinate progress
		¥ Bug fixes
		¥ First localized version.  Includes Japanese, Italian, and English languages.
	0.3.4b
		¥ New memory info window displays DIMM information
		¥ New report window displays test results in human-readable format
		¥ Rember now delays scheduled system sleep while tests are running
		¥ Uses new version of memtest executable (4.2)
 
	0.3.5b
		¥ New icon and images
		¥ Memory info window now compatible with Snow Leopard
		¥ Improved progress display and output parsing
*/

#import <Cocoa/Cocoa.h>
#import "TaskWrapper.h"
#import "killEveryoneButMe.h"
#include <mach-o/arch.h>

// includes for system power notifications
#include <ctype.h> 
#include <stdlib.h> 
#include <stdio.h> 
#include <mach/mach_port.h> 
#include <mach/mach_interface.h> 
#include <mach/mach_init.h> 
#include <IOKit/pwr_mgt/IOPMLib.h> 
#include <IOKit/IOMessage.h> 

@interface RemberController : NSObject <TaskWrapperController>
{
	// NSTextFields
    IBOutlet NSTextField *amountTextField, *loopTextField, *loopsTextField, *loopsCompletedTextField;
    IBOutlet id statusTextField;
	
	// NSButtons
	IBOutlet id maxButton, allButton, mbButton, testButton, verboseButton, quitAllButton, 
		quitFinderButton, verboseButton2, verboseButton3, quitAllButton2, quitFinderButton2, 
		saveButton, okButton, errorButton, reportButton;
	
	// NSMatrix
    IBOutlet id memoryMatrix;
	
	// NSProgressIndicator
	IBOutlet id testProgress;
	
	//Log
	IBOutlet id testLog;
	// preferences window
	IBOutlet id Preferences;
	// memory info window
	IBOutlet id MemoryInfo;
	
	IBOutlet id MemoryView1, MemoryView2, MemoryView3, MemoryView4, MemoryView8, infoStatusView1, infoStatusView2, infoStatusView3, infoStatusView4, infoStatusView8, InfoStatusView;
	
	IBOutlet id infoSlotTextField, infoSizeTextField, infoSpeedTextField, infoStatusTextField, infoTypeTextField;
	
	IBOutlet id memoryInfoButton, memoryInfoButton2;
	
	// TaskWrapper for memtest task calls
	TaskWrapper * remberTask;
	
	// Array for storing memory information
	NSArray * memoryInfo;
	
	// Memory test report window IBOutlets
	IBOutlet id Report, reportSaveButton, reportPrintButton, reportOKButton, reportTextView;
	NSMutableDictionary * reportDict;
	
	// Preferences
	
	// rember is running BOOL
	BOOL remberRunning;
	// stop on error BOOL
	BOOL continueOnError;
	// quit all before launching BOOL
	BOOL quitAll;
	// quit finder before launching BOOL (quitAll must be TRUE for quitFinder to be TRUE)
	BOOL quitFinder;
	// max test loops BOOL
	BOOL maxLoops;
	// test all memory BOOL
	BOOL allMemory;
	// show report BOOL
	BOOL showReport;
	
	// number of total loops, and loops completed
	int totalLoops, loopsCompleted, amount;

}

NSArray * testList, * progressList;
BOOL verbose, showMemoryInfo;
int terminationStatus;
int processID;
	
// system power change notification variables
io_connect_t root_port; 
IONotificationPortRef notify; 
io_object_t anIterator; 

// system power change event notification callback
void callback(void *x,io_service_t y,natural_t messageType,void* messageArgument);

// kill everyone but me declaration
void KillEveryone(Boolean KillFinderToo);

- (id) updatePreferencesPanel;
- (int) openTask:(NSString*)path withArguments:(NSArray*)arguments;

- (IBAction)amountTextFieldAction:(id)sender;
- (IBAction)loopTextFieldAction:(id)sender;
- (IBAction)testButtonAction:(id)sender;
- (IBAction) maxButtonAction:(id)sender;
- (IBAction) allButtonAction:(id)sender;
- (IBAction) mbButtonAction:(id)sender;
- (IBAction) verboseButtonAction:(id)sender;
- (IBAction) quitAllButtonAction:(id)sender;
- (IBAction) quitFinderButtonAction:(id)sender;
- (IBAction) saveButtonAction:(id)sender;
- (IBAction) reportSaveButtonAction:(id)sender;
- (IBAction) errorButtonAction:(id)sender;
- (IBAction) infoOKButtonAction:(id)sender;
- (IBAction) updateMemoryInfoPanel:(id)sender;
- (IBAction) reportSaveButtonAction:(id)sender;
- (IBAction) reportOKButtonAction:(id)sender;
- (IBAction) reportButtonAction:(id)sender;
- (IBAction) memoryInfoButtonAction:(id)sender;

- (IBAction) beginReportPanel:(id)self;
- (NSArray *) memoryInfo;
- (int) updateMemoryInfo;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app;
- (BOOL) isSnowLeopard;

@end
