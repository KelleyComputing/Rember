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
*/

#import <Cocoa/Cocoa.h>
#import "TaskWrapper.h"
#import "killEveryoneButMe.h"

@interface RemberController : NSObject <TaskWrapperController>
{
	// NSTextFields
    IBOutlet NSTextField *amountTextField, *loopTextField, *loopsTextField, *loopsCompletedTextField;
    IBOutlet id statusTextField;
	
	// NSButtons
	IBOutlet id infiniteButton, allButton, mbButton, testButton, verboseButton, quitAllButton, 
		quitFinderButton, verboseButton2, verboseButton3, quitAllButton2, quitFinderButton2, saveButton, okButton;
	
	// NSMatrix
    IBOutlet id memoryMatrix;
	
	//Log
	IBOutlet id testLog;
	// preferences window
	IBOutlet id Preferences;
    // test progress indicator
	IBOutlet NSProgressIndicator *testProgress;
	// TaskWrapper for memtest task calls
	TaskWrapper * remberTask;
	// rember is running BOOL
	BOOL remberRunning;
	// number of total loops, and loops completed
	int totalLoops, loopsCompleted;
}

NSArray * testList, * progressList;
BOOL verbose;
int terminationStatus;
int processID;

void KillEveryone(Boolean KillFinderToo);
- (void) killTask;
- (int) openTask:(NSString*)path withArguments:(NSArray*)arguments;
- (IBAction)loopTextFieldAction:(id)sender;
- (IBAction)testButtonAction:(id)sender;
- (IBAction) infiniteButtonAction:(id)sender;
- (IBAction) allButtonAction:(id)sender;
- (IBAction) mbButtonAction:(id)sender;
- (IBAction) verboseButtonAction:(id)sender;
- (IBAction) quitAllButtonAction:(id)sender;
- (IBAction) quitFinderButtonAction:(id)sender;
- (IBAction) saveButtonAction:(id)sender;
@end
