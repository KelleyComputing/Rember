/* 
RemberController.h
 
RemberController class definition.
 
 Controls program interaction between TaskWrapper and Interface
 
Copyright (C) 2004  KelleyComputing
Author: EK

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

@interface RemberController : NSObject <TaskWrapperController>
{
    IBOutlet NSTextField *amountTextField;
    IBOutlet id infiniteButton, allButton, mbButton, testButton;
    IBOutlet NSTextField *loopTextField;
	IBOutlet id statusTextField;
    IBOutlet id memoryMatrix;
    IBOutlet id testLog;
    IBOutlet NSProgressIndicator *testProgress;
	TaskWrapper * remberTask;
	BOOL remberRunning;
}

int terminationStatus;
int processID;

- (void) killTask;
- (int) openTask:(NSString*)path withArguments:(NSArray*)arguments;
- (IBAction)testButtonAction:(id)sender;
- (IBAction) infiniteButtonAction:(id)sender;
- (IBAction) allButtonAction:(id)sender;
- (IBAction) mbButtonAction:(id)sender;
@end
