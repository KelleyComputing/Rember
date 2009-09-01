/*
RemberController.m
 
RemberController class implementation.

Controls program interaction between TaskWrapper and Interface

Copyright (C) 2004  Eddie Kelley  <eddie@kelleycomputing.net>
 
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
					¥ memtest 4.0.4M executable included
					¥ switched to spinning progress indicator
				0.2.0b
					¥ total GUI overhaul.  
					¥ Preferences added.  
					¥ Verbose logging (filtering) function added
					¥ Test progress in status field
					¥ loop counter
					¥ application/Finder quit functions
 */

#import "RemberController.h"

@implementation RemberController

- (void) awakeFromNib
{
	processID = 0;
	terminationStatus = 0;
	verbose = FALSE;
	
	// loop information
	loops = 1;
	loopsCompleted = 0;
	[loopsTextField setStringValue:[[NSNumber numberWithInt:loops] stringValue]];
	[loopsCompletedTextField setStringValue:[[NSNumber numberWithInt:loopsCompleted] stringValue]];
}

#pragma mark UI actions

- (IBAction) verboseButtonAction:(id)sender
{
	//if(([verboseButton state] == 1) || ([verboseButton2 state] == 1) || ([verboseButton3 state] == 1)){
	if([sender state] == 1){
		verbose = TRUE;
		[verboseButton setState:1];
		[verboseButton2 setState:1];
		[verboseButton3 setState:1];
	}
	else if([sender state] == 0){
		verbose = FALSE;
		[verboseButton setState:0];
		[verboseButton2 setState:0];
		[verboseButton3 setState:0];
	}
}

- (IBAction) quitAllButtonAction:(id)sender
{
	if ([sender state] == 1){
        [quitFinderButton setEnabled:YES];
        [quitFinderButton2 setEnabled:YES];
		[quitAllButton setState:1];
		[quitAllButton2 setState:1];
	}
	else
	{
		[quitFinderButton setEnabled:NO];
        [quitFinderButton2 setEnabled:NO];
		[quitAllButton setState:0];
		[quitAllButton2 setState:0];
		[quitFinderButton setState:0];
		[quitFinderButton2 setState:0];
	}
}

- (IBAction) quitFinderButtonAction:(id)sender
{
	if ([sender state] == 1){
		[quitFinderButton setState:1];
		[quitFinderButton2 setState:1];
	}
	else
	{
		[quitFinderButton setState:0];
		[quitFinderButton2 setState:0];
	}
}


- (IBAction) infiniteButtonAction:(id)sender
{
	if ([infiniteButton state] == 1){
        [loopTextField setEnabled:NO];
		[loopsTextField setStringValue:@"°"];
	}
	else
	{
        [loopTextField setEnabled:YES];
		[loopsTextField setStringValue:[loopTextField stringValue]];
	}
}

- (IBAction) allButtonAction:(id)sender
{
	if ([allButton state] == 1){
        [memoryMatrix selectCellWithTag:0];
        [amountTextField setEnabled:NO];
	}
	else{
		[memoryMatrix selectCellWithTag:1]; 
		[amountTextField setEnabled:YES];
	}
}

- (IBAction) mbButtonAction:(id)sender
{
    if ([mbButton state] == 1){
        [memoryMatrix selectCellWithTag:1]; 
		[amountTextField setEnabled:YES];
	} 
	else{
		[memoryMatrix selectCellWithTag:0];
		[amountTextField setEnabled:NO];
	}
}

-(IBAction)loopTextFieldAction:(id)sender
{
	if(!remberRunning){
		[loopsTextField setStringValue:[loopTextField stringValue]];
		loops = [loopTextField intValue];
	}
}

- (IBAction)testButtonAction:(id)sender
{
	if(!remberRunning){
		// variables
		NSString *loopsString, *amount;
		
		// if the user has chosen, quit Finder and all Apps
		
		if([quitAllButton state] == 1)
			KillEveryone(false);
		if([quitFinderButton state] == 1)
			KillEveryone(true);
		
		// reset session counters
		loopsCompleted = 0;
		[loopsCompletedTextField setStringValue:[[NSNumber numberWithInt:loopsCompleted] stringValue]];
		
		// determine number of loops to do
		if([infiniteButton state] == 1)
		{
			// loop indefinitely
			loopsString = [NSString stringWithString:@""];
		}
		else
		{
			// if we aren't looping infinitely, set the loopsString to the loopTextField string
			loops = [loopTextField intValue];
			loopsString = [NSString stringWithString:[loopTextField stringValue]];
			[loopsTextField setStringValue:loopsString];
		}
		
		// determine amount of memory to test
		if([allButton state] == 1)
			amount = [NSString stringWithString:@"all"];
		else
			amount = [NSString stringWithString:[amountTextField stringValue]];
		
		// open the memtest task and capture it's processID
		processID = [self openTask:[[NSBundle mainBundle] pathForResource:@"memtest" ofType:nil] 
					 withArguments:[NSArray arrayWithObjects:amount, loopsString, nil]];
		
		if(processID > 0)
		{
			[statusTextField setStringValue:@"Testing..."];
		}
		else
		{
			[statusTextField setStringValue:@"An error occurred during initialization."];
		}
	}
	else
	{
		[self killTask];
	}
}

#pragma mark TaskWrapper Controller tasks

-(void) killTask
{
	if (remberRunning!=nil)
		[remberTask release];
}

-(int) openTask:(NSString*)path withArguments:(NSArray*)arguments
{
	// Variables
	int processID = 0;
	NSMutableArray *args = [NSMutableArray arrayWithCapacity:1];
	
	// Set launch arguments
	[args addObject:path];
	[args addObjectsFromArray:arguments];
	
	// If the task is already running, release
	if (remberRunning!=nil)
        [remberTask release];
	// Let's allocate memory for and initialize a new TaskWrapper object, passing
	// in ourselves as the controller for this TaskWrapper object, the path
	// to the command-line tool, and the contents of the text field that 
	// displays what the user wants to search on
	remberTask=[[TaskWrapper alloc] initWithController:self arguments:args];
		// kick off the process asynchronously
	[remberTask startProcess];
	processID = [remberTask processID];
	return processID;
}


// This callback is implemented as part of conforming to the ProcessController protocol.
// It will be called whenever there is output from the TaskWrapper.
- (void)appendOutput:(NSString *)output
{
	// variables
	
	// testList: these are test strings that we must scan the output for,
	//		to determine which test is running.  This is fairly primitive, 
	//		but it's easy not to have to link to memtest code.
	NSArray * testList = [NSArray arrayWithObjects:	
		@"Stuck Address",
		@"ok\n  Random Value",
		@"Compare XOR", 
		@"Compare SUB", 
		@"Compare MUL", 
		@"Compare DIV", 
		@"Compare OR", 
		@"Compare AND",
		@"Sequential Increment",
		@"Solid Bits",
		@"Block Sequential",
		@"Checkerboard",
		@"Bit Spread",
		@"Bit Flip",
		@"Walking Ones",
		@"Walking Zeroes", nil];
	
	// these are strings that i have deemed the "verbose" information, 
	//		that if a users pleases, can be with-held.
	NSArray * progressList = [NSArray arrayWithObjects: 
		@"\b\b\b\b\b\b\b\b\b\b\b           \b\b\b\b\b\b\b\b\b\b\b",
		@"\b\b\b\b\b\b\b\b\b\b\b", 
		@"\b-", 
		@"\b|", 
		@"\b/", 
		@"\b\\", 
		@"\b\b\b\b\b\b\b\b\b\b\btesting", 
		@"\b\b\b\b\b\b\b\b\b\b\bsetting",
		@"setting",
		@"testing", nil];
	int i = 0;
	NSString *temp = nil;
	
	// init a scanner with our output string
	NSScanner *outputScanner = [NSScanner scannerWithString:output];
	[outputScanner setCharactersToBeSkipped:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
	// init outputScanner with the output from TaskWrapper
	outputScanner = [NSScanner scannerWithString:output];
	
	// determine if we're in verbose mode
	if(!verbose){
		// determine if the output is CLI 'garbage'
		//
		// if the string doesn't match progress junk strings, 
		//		continue.
		while (i < [progressList count])
		{
			if([outputScanner scanString:[progressList objectAtIndex:i] intoString:&temp])
			{
				i = [progressList count];
				return;		// if the output is junk, return without displaying
			}
			else{
				i++;
				temp = nil;
			}
		}
	}
	
	// use scanner to determine which test is being run (if any),
	//	and display information in statusTextField
	i = 0;
	while(i < [testList count]){
		if([outputScanner scanString:[testList objectAtIndex:i] intoString:&temp])
		{
			//NSLog(output);
			
			// this is a hack to display 'Running test' value correctly
			// Rember takes the output as it gets it - this is one drawback
			if(i != 1)
			{
				[statusTextField setStringValue:[@"Running test: " stringByAppendingString:[testList objectAtIndex:i]]]; // 'normal' output (methinks earlier versions of memtest)
			}
			else{
				[statusTextField setStringValue:@"Running test: Random Value"]; // hack pretty string in here for inconsistent output strings
			}
			i = [testList count];
			temp = nil;
		}
		else{
			temp = nil;
			i++;
		}
	}
	
	// Get test sequence string, increase loopsCompleted number
	if([outputScanner scanString:@"Test sequence" intoString:&temp])
	{
		loopsCompleted++;
		[loopsCompletedTextField setStringValue:[[NSNumber numberWithInt:loopsCompleted] stringValue]];
	}
	
	// Get 'All tests passed' string.  Re-assure user of tests passing.
	if([outputScanner scanString:@"All tests passed.\n\n" intoString:&temp])
	{
		if([infiniteButton state] != 1){
			loopsCompleted++;
			[loopsCompletedTextField setStringValue:[[NSNumber numberWithInt:loopsCompleted] stringValue]];
		}
		[statusTextField setStringValue:@"All tests passed"];
	}
	
	// none of the progress phrases were found, or we are in verbose mode.  Display output
	// add the string (a chunk of the results from locate) to the NSTextView's
	// backing store, in the form of an attributed string
	[[testLog textStorage] appendAttributedString: [[[NSAttributedString alloc]
								initWithString: output] autorelease]];
	// setup a selector to be called the next time through the event loop to scroll
	// the view to the just pasted text.  We don't want to scroll right now,
	// because of a bug in Mac OS X version 10.1 that causes scrolling in the context
	// of a text storage update to starve the app of events
	[self performSelector:@selector(scrollToVisible:) withObject:nil afterDelay:0.0];
}

// This routine is called after adding new results to the text view's backing store.
// We now need to scroll the NSScrollView in which the NSTextView sits to the part
// that we just added at the end
- (void)scrollToVisible:(id)ignore {
    [testLog scrollRangeToVisible:NSMakeRange([[testLog string] length], 0)];
}

// A callback that gets called when a TaskWrapper is launched, allowing us to do any setup
// that is needed from the app side.  This method is implemented as a part of conforming
// to the ProcessController protocol.
- (void)processStarted
{
	loopsCompleted = 0; 
    remberRunning = YES;
    // clear the results
    [testLog setString:@""];
	[statusTextField setStringValue:@"Initializing..."];
	[testProgress startAnimation:self];
    // change the "Test" button to say "Stop"
    [testButton setTitle:@"Stop"];
	// disable other user controls
	[loopTextField setEnabled:NO];
	[amountTextField setEnabled:NO];
	[infiniteButton setEnabled:NO];
	[memoryMatrix setEnabled:NO];
	
}

// A callback that gets called when a TaskWrapper is completed, allowing us to do any cleanup
// that is needed from the app side.  This method is implemented as a part of conforming
// to the ProcessController protocol.
- (void)processFinished
{
    remberRunning=NO;
	[testProgress stopAnimation:self];
	
	[statusTextField setStringValue:@"Idle"];
    
	// change the button's title back for the next search
    [testButton setTitle:@"Test"];
	
	//re-enable user controls (to pre-test state)
	if([infiniteButton state] == 1)
		[loopTextField setEnabled:NO];
	else
		[loopTextField setEnabled:YES];
	if([allButton state] == 1)
		[amountTextField setEnabled:NO];
	else
		[amountTextField setEnabled:YES];
	[infiniteButton setEnabled:YES];
	[memoryMatrix setEnabled:YES];
	
}

// If the user closes the window, let's just quit
-(BOOL)windowShouldClose:(id)sender
{
    [NSApp terminate:nil];
    return YES;
}

#pragma mark killEveryOneButMe

OSErr SendQuitAppleEventToApplication(ProcessSerialNumber ProcessToQuit)
{
    OSErr errorToReturn;
    AEDesc targetProcess;
    AppleEvent theEvent;
    AppleEvent eventReply = {typeNull, NULL}; 
	
    errorToReturn = AECreateDesc(typeProcessSerialNumber, &ProcessToQuit, 
								 sizeof(ProcessToQuit), &targetProcess);
	
    if (errorToReturn != noErr)
	{return(errorToReturn);}
    
    errorToReturn = AECreateAppleEvent(kCoreEventClass, kAEQuitApplication, &targetProcess, 
									   kAutoGenerateReturnID, kAnyTransactionID, &theEvent);
	
    AEDisposeDesc(&targetProcess); //done with target process descriptor so dispose
	
    if (errorToReturn != noErr)
	{return(errorToReturn);}
    
    errorToReturn = AESend(&theEvent, &eventReply, kAENoReply + kAEAlwaysInteract, kAENormalPriority, kAEDefaultTimeout, NULL, NULL);
	
    AEDisposeDesc(&theEvent); //done with event so dispose
    AEDisposeDesc(&eventReply); 
    
    return(errorToReturn);
}


/* This is the killer code.  It finds and kills every other  */
/* application on your machine (quitting them using quit apple events) */
void KillEveryone(Boolean KillFinderToo)
{
    ProcessSerialNumber nextProcessToKill = {kNoProcess, kNoProcess};
    ProcessSerialNumber finderPSN; //we need to record this since finder must be quit last.
    ProcessSerialNumber ourPSN;
    OSErr error, otherError;
    ProcessInfoRec infoRec;
    Str31 processName;
	
    Boolean processIsFinder;
    Boolean processIsUs;
    Boolean specialMacOSXProcessWhichWeShouldNotKill;
    Boolean finderFound = false;
    Boolean thisIsMacOSX, weAreRunningInClassic;
    long	response;
	
    GetCurrentProcess(&ourPSN);
	
    //before we start we need to see if this is Mac OS X.  On Mac OS X certain applications shouldn't be quit by processes.
    //such as loginwindow and the dock
    error = Gestalt(gestaltMenuMgrAttr, &response);
    if ((error == noErr) && ((response & gestaltMenuMgrAquaLayoutMask) != 0))
	{thisIsMacOSX = TRUE;}
    else
	{thisIsMacOSX = FALSE;}
	
    //Check to see if we are running in classic on MacOSX
    error = Gestalt(gestaltMacOSCompatibilityBoxAttr, &response);
    if ((error == noErr) && (response == gestaltMacOSCompatibilityBoxPresent))
	{weAreRunningInClassic = TRUE;}
    else
	{weAreRunningInClassic = FALSE;}
    
    do
    {
        error = GetNextProcess(&nextProcessToKill);
        
        if (error == noErr)
        {
            //First check if its us
            SameProcess(&ourPSN, &nextProcessToKill, &processIsUs);
            
            if (processIsUs == FALSE)
            {
                infoRec.processInfoLength = sizeof(ProcessInfoRec);
                infoRec.processName = processName;
                infoRec.processAppSpec = NULL;
				
                otherError = GetProcessInformation(&nextProcessToKill, &infoRec);
				
                if (otherError == noErr)
                {
                    processIsFinder = FALSE;
					
                    // First check to see if it's the Finder, we have to kill the finder LAST on classic MacOS (MacOS9 and previous
                    // Reason is because the Finder must be around to pass on the AppleEvent.
                    if (finderFound == FALSE)
                    {
                        if (infoRec.processSignature == 'MACS' && infoRec.processType == 'FNDR') 
                        {
                            // save finder PSN for later
                            finderPSN = nextProcessToKill;
                            finderFound = TRUE;
                            processIsFinder = TRUE;
                        }
                    }
                    
                    //since this is MacOSX we need to make sure we don't quit certain applications 
                    if ((thisIsMacOSX == TRUE) || (weAreRunningInClassic == TRUE))
                    {
                        if (infoRec.processSignature == 'lgnw' && infoRec.processType == 'APPL')
                        {
                            //don't want to quit loginwindow on MacOSX or system will logout
                            specialMacOSXProcessWhichWeShouldNotKill = TRUE;
                        }
                        else if (infoRec.processSignature == 'dock' && infoRec.processType == 'APPL')
                        {
                            //don't want to quit Dock on MacOSX it provides important support (for example Command+Tab switching)
                            specialMacOSXProcessWhichWeShouldNotKill = TRUE;
                        }
                        else if (infoRec.processSignature == 'syui' && infoRec.processType == 'APPL')
                        {
                            //don't want to quit the SystemUI server on MacOSX this offers important system support
                            specialMacOSXProcessWhichWeShouldNotKill = TRUE;
                        }
                        else if (infoRec.processSignature == 'bbox' && infoRec.processType == 'APPL')
                        {
                            //don't want to quit the "special" bluebox envionment process directly (as it can cause havoc).  
                            //Instead this process will quit indirectly when the "real" Classic envonment gets its quit event
                            specialMacOSXProcessWhichWeShouldNotKill = TRUE;
                        }
                        else
                        {
                            specialMacOSXProcessWhichWeShouldNotKill = FALSE; //this isn't a special process
                        }
                    }
                    else //this is MacOS9 or previous
					{specialMacOSXProcessWhichWeShouldNotKill = FALSE;}
                    
                    if ((processIsFinder == FALSE) && (specialMacOSXProcessWhichWeShouldNotKill == FALSE))
                    {
                        //ignore return value
                        (void)SendQuitAppleEventToApplication(nextProcessToKill);
                    }
                }
            }
        }
    }
    while (error == noErr);
	
    /* Now, if the finder was running (and we want to quit it) then it's safe to kill it */
    if ((finderFound == TRUE) && (KillFinderToo == TRUE))
    {
        //ignore return value
        (void)SendQuitAppleEventToApplication(finderPSN);
    }
}   

@end
