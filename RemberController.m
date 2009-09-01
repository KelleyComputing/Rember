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

 */

#import "RemberController.h"

@implementation RemberController

- (void) awakeFromNib
{	
	// set temporary loop information
	loopsCompleted = 0;
	[loopsCompletedTextField setStringValue:[[NSNumber numberWithInt:loopsCompleted] stringValue]];
	
	// set preferences
	[self updatePreferencesPanel];
}

- (id)updatePreferencesPanel
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	if([defaults objectForKey:@"stopOnError"] != nil)
	{	
		stopOnError = [defaults boolForKey:@"stopOnError"];
		[errorButton setState:!stopOnError];
	}
	else
	{
		stopOnError = FALSE;
		[errorButton setState:!stopOnError];
		[defaults setBool:stopOnError forKey:@"stopOnError"];
	}
	
	if([defaults objectForKey:@"verbose"] != nil)
	{
		verbose = [defaults boolForKey:@"verbose"];
		[verboseButton setState:verbose];
		[verboseButton2 setState:verbose];
		[verboseButton3 setState:verbose];
	}
	else
	{
		verbose= FALSE;
		[verboseButton setState:verbose];
		[verboseButton2 setState:verbose];
		[verboseButton3 setState:verbose];
		[defaults setBool:verbose forKey:@"verbose"];
	}
	
	if([defaults objectForKey:@"quitAll"] != nil)
	{
		quitAll = [defaults boolForKey:@"quitAll"];
		[quitAllButton setState:quitAll];
		[quitAllButton2 setState:quitAll];
	}
	else
	{
		quitAll = FALSE;
		[quitAllButton setState:quitAll];
		[quitAllButton2 setState:quitAll];
		[defaults setBool:quitAll forKey:@"quitAll"];
	}
	
	if([defaults objectForKey:@"quitFinder"] != nil)
	{
		quitFinder = [defaults boolForKey:@"quitFinder"];
		[quitFinderButton setState:quitFinder];
		[quitFinderButton2 setState:quitFinder];
	}
	else
	{
		quitFinder = FALSE;
		[quitFinderButton setState:quitFinder];
		[quitFinderButton2 setState:quitFinder];
		[defaults setBool:quitFinder forKey:@"quitFinder"];
	}
	
	if([defaults objectForKey:@"totalLoops"] != nil)
	{
		totalLoops = [[defaults objectForKey:@"totalLoops"] intValue];
		[loopTextField setIntValue:totalLoops];
		[loopsTextField setIntValue:totalLoops];
	}
	else
	{
		totalLoops = 1;
		[loopTextField setIntValue:1];
		[loopsTextField setIntValue:1];
		[defaults setObject:[NSNumber numberWithInt:totalLoops] forKey:@"totalLoops"];
	}
	
	if([defaults objectForKey:@"infiniteLoops"] != nil)
	{
		infiniteLoops = [defaults boolForKey:@"infiniteLoops"];
		[infiniteButton setState:infiniteLoops];
		
		if(infiniteLoops)
			[loopTextField setEnabled:FALSE];
		else
			[loopTextField setEnabled:TRUE];
	}
	else
	{
		infiniteLoops = FALSE;
		[infiniteButton setState:infiniteLoops];
		[defaults setBool:infiniteLoops forKey:@"infiniteLoops"];
		[loopTextField setEnabled:TRUE];
		
	}
	
	if([defaults objectForKey:@"allMemory"] != nil)
	{
		allMemory = [defaults boolForKey:@"allMemory"];
		[allButton setState:allMemory];
		[mbButton setState:!allMemory];
		[amountTextField setEnabled:FALSE];
	}
	else
	{
		allMemory = FALSE;
		[allButton setState:allMemory];
		[mbButton setState:!allMemory];
		[amountTextField setEnabled:TRUE];
		[defaults setBool:allMemory forKey:@"allMemory"];
	}


	
	if([defaults objectForKey:@"amount"] != nil)
	{
		amount = [[defaults objectForKey:@"amount"] intValue];
		[amountTextField setIntValue:amount];
	}
	else
	{
		amount = 1;
		[amountTextField setIntValue:1];
		[defaults setObject:[NSNumber numberWithInt:amount] forKey:@"amount"];
	}
	
	[defaults synchronize];
}

#pragma mark UI actions

-(IBAction) beginPreferencesPanel:(id)sender
{
	[NSApp beginSheet:Preferences
	   modalForWindow:[NSApp mainWindow]
		modalDelegate:self
	   didEndSelector:NULL
		  contextInfo:nil];
}

-(void) endPreferencesPanel
{
	[Preferences orderOut:self];
    [NSApp endSheet:Preferences];
}

-(IBAction) okButtonAction:(id)sender
{
	[self endPreferencesPanel];
}

- (IBAction) verboseButtonAction:(id)sender
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	if([sender state] == 1){
		verbose = TRUE;
		[verboseButton setState:1];
		[verboseButton2 setState:1];
		[verboseButton3 setState:1];
		verbose = TRUE;
	}
	else if([sender state] == 0){
		verbose = FALSE;
		[verboseButton setState:0];
		[verboseButton2 setState:0];
		[verboseButton3 setState:0];
		verbose = FALSE;
	}
	
	[defaults setBool:verbose forKey:@"verbose"];
	[defaults synchronize];
}

- (IBAction) quitAllButtonAction:(id)sender
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	quitAll = FALSE;
	
	if ([sender state] == 1){
        [quitFinderButton setEnabled:YES];
        [quitFinderButton2 setEnabled:YES];
		[quitAllButton setState:1];
		[quitAllButton2 setState:1];
		quitAll = TRUE;
	}
	else
	{
		[quitFinderButton setEnabled:NO];
        [quitFinderButton2 setEnabled:NO];
		[quitAllButton setState:0];
		[quitAllButton2 setState:0];
		[quitFinderButton setState:0];
		[quitFinderButton2 setState:0];
		quitAll = FALSE;
		quitFinder = FALSE;
	}
	
	[defaults setBool:quitAll forKey:@"quitAll"];
	[defaults setBool:quitFinder forKey:@"quitFinder"];
	[defaults synchronize];
}

- (IBAction) quitFinderButtonAction:(id)sender
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	quitFinder = FALSE;
	
	if ([sender state] == 1){
		[quitFinderButton setState:1];
		[quitFinderButton2 setState:1];
		quitFinder = TRUE;
	}
	else
	{
		[quitFinderButton setState:0];
		[quitFinderButton2 setState:0];
		quitFinder = FALSE;
	}
	
	[defaults setBool:quitFinder forKey:@"quitFinder"];
	[defaults synchronize];
}


- (IBAction) infiniteButtonAction:(id)sender
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	infiniteLoops = FALSE;
	
	if ([infiniteButton state] == 1){
        [loopTextField setEnabled:NO];
		[loopsTextField setStringValue:@"°"];
		 infiniteLoops = TRUE;
	}
	else
	{
        [loopTextField setEnabled:YES];
		[loopsTextField setStringValue:[loopTextField stringValue]];
		 infiniteLoops = FALSE;
	}
	
	[defaults setBool:infiniteLoops forKey:@"infiniteLoops"];
	[defaults synchronize];
}

- (IBAction) allButtonAction:(id)sender
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	allMemory = TRUE;
		
	if ([allButton state] == 1){
        [memoryMatrix selectCellWithTag:0];
        [amountTextField setEnabled:NO];
		allMemory = TRUE;
	}
	else{
		[memoryMatrix selectCellWithTag:1]; 
		[amountTextField setEnabled:YES];
		allMemory = FALSE;
	}
	
	[defaults setBool:allMemory forKey:@"allMemory"];
	[defaults synchronize];
}

- (IBAction) mbButtonAction:(id)sender
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	allMemory = FALSE;
	
    if ([mbButton state] == 1){
        [memoryMatrix selectCellWithTag:1]; 
		[amountTextField setEnabled:YES];
		allMemory = FALSE;
	} 
	else{
		[memoryMatrix selectCellWithTag:0];
		[amountTextField setEnabled:NO];
		allMemory = TRUE;
	}
	
	[defaults setBool:allMemory forKey:@"allMemory"];
	[defaults synchronize];
}

-(IBAction)amountTextFieldAction:(id)sender
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	amount = 1;
	
	if(!remberRunning){
		amount = [amountTextField intValue];
	}
	
	[defaults setObject:[NSNumber numberWithInt:amount] forKey:@"amount"];
	[defaults synchronize];
}

-(IBAction)loopTextFieldAction:(id)sender
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

	if(!remberRunning){
		[loopsTextField setStringValue:[loopTextField stringValue]];
		totalLoops = [loopTextField intValue];
	}
	
	[defaults setObject:[NSNumber numberWithInt:totalLoops] forKey:@"totalLoops"];
	[defaults synchronize];
}


- (IBAction) errorButtonAction:(id)sender
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	if([sender state] == 1)
	{
		// if the user has chosen to stop testing upon error, set defaults
		stopOnError = FALSE;
	}
	else
	{
		stopOnError = TRUE;
	}
	
	[defaults setBool:stopOnError forKey:@"stopOnError"];
	[defaults synchronize];
}

- (IBAction) saveButtonAction:(id)sender
{
	NSString* filename;
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setRequiredFileType:@"txt"];
	[panel setCanSelectHiddenExtension:YES];
	[panel setExtensionHidden:NO];
    if ([panel runModal] == NSOKButton) {
		filename = [NSString stringWithString:[panel filename]];
		[[[testLog textStorage] string] writeToFile:filename atomically:YES];
	}
}

- (IBAction)testButtonAction:(id)sender
{
	if(!remberRunning){
		// variables
		NSString *loopsString, *amountString;
		
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
			totalLoops = [loopTextField intValue];
			loopsString = [NSString stringWithString:[loopTextField stringValue]];
			[loopsTextField setStringValue:loopsString];
		}
		
		// determine amount of memory to test
		if([allButton state] == 1)
			amountString = [NSString stringWithString:@"all"];
		else
			amountString = [NSString stringWithString:[amountTextField stringValue]];
		
		// open the memtest task and capture it's processID
		processID = [self openTask:[[NSBundle mainBundle] pathForResource:@"memtest" ofType:nil] 
					 withArguments:[NSArray arrayWithObjects:amountString, loopsString, nil]];
		
		// if the process has started, post status.
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
		// the 'stop' button was clicked.  terminate task.
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
	
	// Get 'FAILURE' string. 
	if([outputScanner scanString:@"FAILURE:" intoString:&temp])
	{
		[statusTextField setStringValue:@"FAILURE - see log for more info"];
		if([errorButton state] != 1){
			[self killTask];
			NSRunAlertPanel(@"Rember", @"Errors were detected.  See log for more details.", @"OK", @"", @"");
		}
	}
	
	if(output != nil){
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
	[testProgress setUsesThreadedAnimation:TRUE];
	[testProgress startAnimation:self];
	
    // change the "Test" button to say "Stop"
    [testButton setTitle:@"Stop"];
	
	// disable other user controls while testing
	[loopTextField setEnabled:NO];
	[amountTextField setEnabled:NO];
	[infiniteButton setEnabled:NO];
	[memoryMatrix setEnabled:NO];
	[quitAllButton setEnabled:NO];
	[quitFinderButton setEnabled:NO];
	
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
	[quitAllButton setEnabled:YES];
	if([quitAllButton state] == 1)
		[quitFinderButton setEnabled:YES];
	terminationStatus = [remberTask terminationStatus];
	if((terminationStatus != 0) && (terminationStatus != 15))
	{
		NSRunAlertPanel(@"Rember", @"Errors were detected.  See log for more details.", @"OK", @"", @"");
	}
	
}

// If the user closes the window, let's just quit
-(BOOL)windowShouldClose:(id)sender
{
	if(remberRunning)
		if(NSRunAlertPanel(@"Rember", @"Memory tests are still in progress.  Are you sure you want to quit?", @"OK", @"Cancel", @"") == NSOKButton)
			return YES;
		else
			return NO;
	else
		return YES;
}

-(void)windowWillClose:(id)sender
{
	[self killTask];
	[NSApp terminate:nil];
}

@end
