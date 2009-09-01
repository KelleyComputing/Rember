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
	// testList: these are test strings that we must scan the output for,
	//		to determine which test is running.  This is fairly primitive, 
	//		but it's easy not to have to link to memtest code.
	testList = [[NSArray alloc] initWithObjects:	
		@"Stuck Address",
		@"Linear PRN",
		@"Random Value",
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
	progressList =[[NSArray alloc] initWithObjects: 
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
	
	memoryInfo = [[NSArray alloc] initWithArray:[self memoryInfo]];

	// register for system power event changes (disable system sleep)
	root_port = IORegisterForSystemPower (0,&notify,callback,&anIterator); 
	if ( &root_port == NULL ) { 
		printf("IORegisterForSystemPower failed\n"); 
	} 
	CFRunLoopAddSource(CFRunLoopGetCurrent(), 
					   IONotificationPortGetRunLoopSource(notify), 
					   kCFRunLoopDefaultMode);
	
	// Dictionary to store report information in
	reportDict = [[NSMutableDictionary alloc] initWithCapacity:1];
	
	// Determine if the user has chosen to display memory info at program startup
	if(showMemoryInfo)
	{
		NSTimer *timer;
		timer = [NSTimer scheduledTimerWithTimeInterval:1 
												 target:self 
											   selector:@selector(showMemoryInfoPanel) 
											   userInfo:nil 
												repeats:NO];	
	}
}


- (id)updatePreferencesPanel
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	if([defaults objectForKey:@"showMemoryInfo"] != nil)
	{	
		showMemoryInfo = [defaults boolForKey:@"showMemoryInfo"];
		[memoryInfoButton setState:showMemoryInfo];
		[memoryInfoButton2 setState:showMemoryInfo];
	}
	else
	{
		showMemoryInfo = TRUE;
		[memoryInfoButton setState:showMemoryInfo];
		[memoryInfoButton2 setState:showMemoryInfo];
		[defaults setBool:showMemoryInfo forKey:@"showMemoryInfo"];
	}
	
	if([defaults objectForKey:@"continueOnError"] != nil)
	{	
		continueOnError = [defaults boolForKey:@"continueOnError"];
		[errorButton setState:continueOnError];
	}
	else
	{
		continueOnError = FALSE;
		[errorButton setState:continueOnError];
		[defaults setBool:continueOnError forKey:@"continueOnError"];
	}
	
	if([defaults objectForKey:@"showReport"] != nil)
	{
		showReport = [defaults boolForKey:@"showReport"];
		[reportButton setState:showReport];
	}
	else
	{
		showReport = TRUE;
		[reportButton setState:showReport];
		[defaults setBool:showReport forKey:@"showReport"];
	}
	
	if([defaults objectForKey:@"verbose"] != nil)
	{
		verbose = [defaults boolForKey:@"verbose"];
		[verboseButton setState:verbose];
		[verboseButton2 setState:verbose];
	}
	else
	{
		verbose= FALSE;
		[verboseButton setState:verbose];
		[verboseButton2 setState:verbose];
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
		[quitFinderButton setEnabled:quitAll];
		[defaults setBool:quitAll forKey:@"quitAll"];
	}
	
	if([defaults objectForKey:@"quitFinder"] != nil)
	{
		quitFinder = [defaults boolForKey:@"quitFinder"];
		[quitFinderButton setState:quitFinder];
	}
	else
	{
		quitFinder = FALSE;
		[quitFinderButton setState:quitFinder];
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
	
	if([defaults objectForKey:@"maxLoops"] != nil)
	{
		maxLoops = [defaults boolForKey:@"maxLoops"];
		[maxButton setState:maxLoops];
		
		if(maxLoops == YES){
			[loopTextField setEnabled:FALSE];
			[loopTextField setDoubleValue:255];
			[loopsTextField setDoubleValue:255];
		}
		else{
			[loopTextField setEnabled:TRUE];
			[loopTextField setDoubleValue:[[defaults objectForKey:@"totalLoops"] intValue]];
			[loopsTextField setDoubleValue:[[defaults objectForKey:@"totalLoops"] intValue]];
		}
	}
	else
	{
		maxLoops = FALSE;
		[maxButton setState:maxLoops];
		[defaults setBool:maxLoops forKey:@"maxLoops"];
		[loopTextField setStringValue:[[defaults objectForKey:@"totalLoops"] stringValue]];
		[loopTextField setEnabled:TRUE];
		
	}
	
	if([defaults objectForKey:@"allMemory"] != nil)
	{
		allMemory = [defaults boolForKey:@"allMemory"];
		[allButton setState:allMemory];
		[mbButton setState:!allMemory];
		if(allMemory)
			[amountTextField setEnabled:FALSE];
		else
			[amountTextField setEnabled:TRUE];
	}
	else
	{
		allMemory = TRUE;
		[allButton setState:allMemory];
		[mbButton setState:!allMemory];
		[amountTextField setEnabled:FALSE];
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

- (int) updateMemoryInfo
{
	NSString * infoPlistPath = [NSString stringWithString:[@"system_profiler SPMemoryDataType -xml > " stringByAppendingString:[NSHomeDirectory() stringByAppendingString:@"/Library/Preferences/net.kelleycomputing.Rember.memoryInfo.plist"]]];
	NSString * builtInPlistPath = [NSString stringWithString:[@"system_profiler SPHardwareDataType | grep Memory | sed s/.*Memory..// > " stringByAppendingString:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/net.kelleycomputing.Rember.builtInMemory.txt"]]];	
	int status = system([infoPlistPath cString]);
	status += system([builtInPlistPath cString]);
	return status;
}


- (NSArray *) memoryInfo
{
	NSFileManager * fileManager = [NSFileManager defaultManager];
	NSString * infoPlistPath = [NSString stringWithString:[NSHomeDirectory() stringByAppendingString:@"/Library/Preferences/net.kelleycomputing.Rember.memoryInfo.plist"]];
	NSString * builtInPlistPath = [NSString stringWithString:[NSHomeDirectory() stringByAppendingString:@"/Library/Preferences/net.kelleycomputing.Rember.builtInMemory.txt"]];
	[self updateMemoryInfo];
	if([fileManager fileExistsAtPath:infoPlistPath])
	{
		if(![self isSnowLeopard]){
			NSArray *info = [NSArray arrayWithContentsOfFile:infoPlistPath];
			NSDictionary *memoryDict = [NSDictionary dictionaryWithDictionary:[info objectAtIndex:0]];
			NSArray *items = [memoryDict objectForKey:@"_items"];
			return items;	
		}
		else{
			NSArray *info = [NSArray arrayWithContentsOfFile:infoPlistPath];
			NSDictionary *infoDict = [NSDictionary dictionaryWithDictionary:[info objectAtIndex:0]];
			NSDictionary *memoryDict = [NSDictionary dictionaryWithDictionary:[[infoDict objectForKey:@"_items"] objectAtIndex:0]];
			
			NSArray *items = [memoryDict objectForKey:@"_items"];
			
			return items;	
		}
	}
	else
		return nil;
}

- (BOOL) isSnowLeopard{
	NSString *operatingSystemVersion = [[NSProcessInfo processInfo] operatingSystemVersionString], *temp = [NSString stringWithString:@""];
	NSScanner *versionScanner = [NSScanner scannerWithString:operatingSystemVersion];
	
	if([versionScanner scanUpToString:@"(" intoString:&temp]){
		versionScanner = [NSScanner scannerWithString:temp];
		if([versionScanner scanString:@"Version 10.6" intoString:&temp])
			return TRUE;
		else
			return FALSE;
	}
	else
		return FALSE;
}

- (void) showTestResults
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSError * error;
	
	if([defaults boolForKey:@"showReport"]){
		NSMutableDictionary *reportAttrs = [NSMutableDictionary dictionaryWithCapacity:1];
		NSMutableAttributedString * report = [[NSMutableAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Report.rtf" ofType:nil] documentAttributes:&reportAttrs];
		[[report mutableString] replaceOccurrencesOfString:@"TEST_RESULTS" withString:[reportDict objectForKey:@"testResults"] options:nil range:NSMakeRange(0,[[report mutableString] length])];
		if([reportDict objectForKey:@"availableAmount"] != nil)
			[[report mutableString] replaceOccurrencesOfString:@"AVAILABLE_MEMORY" withString:[reportDict objectForKey:@"availableAmount"] options:nil range:NSMakeRange(0,[[report mutableString] length])];
		if([reportDict objectForKey:@"builtInAmount"] != nil)
			[[report mutableString] replaceOccurrencesOfString:@"BUILT_IN_MEMORY" withString:[reportDict objectForKey:@"builtInAmount"] options:nil range:NSMakeRange(0,[[report mutableString] length])];
		if([reportDict objectForKey:@"requestedAmount"] != nil)
			[[report mutableString] replaceOccurrencesOfString:@"MEMORY_REQUESTED" withString:[reportDict objectForKey:@"requestedAmount"] options:nil range:NSMakeRange(0,[[report mutableString] length])];
		if([reportDict objectForKey:@"allocatedAmount"] != nil)
			[[report mutableString] replaceOccurrencesOfString:@"MEMORY_ALLOCATED" withString:[reportDict objectForKey:@"allocatedAmount"] options:nil range:NSMakeRange(0,[[report mutableString] length])];
		if([reportDict objectForKey:@"loops"] != nil)
			[[report mutableString] replaceOccurrencesOfString:@"LOOPS_SELECTED" withString:[reportDict objectForKey:@"loops"] options:nil range:NSMakeRange(0,[[report mutableString] length])];
		if([reportDict objectForKey:@"loopsCompleted"] != nil)
			[[report mutableString] replaceOccurrencesOfString:@"LOOPS_COMPLETED" withString:[reportDict objectForKey:@"loopsCompleted"] options:nil range:NSMakeRange(0,[[report mutableString] length])];
		if([reportDict objectForKey:@"executionTime"] != nil)
			[[report mutableString] replaceOccurrencesOfString:@"EXECUTION_TIME" withString:[reportDict objectForKey:@"executionTime"] options:nil range:NSMakeRange(0,[[report mutableString] length])];
		if([reportDict objectForKey:@"startTime"] != nil)
			[[report mutableString] replaceOccurrencesOfString:@"TEST_START_TIME" withString:[reportDict objectForKey:@"startTime"] options:nil range:NSMakeRange(0,[[report mutableString] length])];
		if([reportDict objectForKey:@"stopTime"] != nil)
			[[report mutableString] replaceOccurrencesOfString:@"TEST_END_TIME" withString:[reportDict objectForKey:@"stopTime"] options:nil range:NSMakeRange(0,[[report mutableString] length])];
		[[reportTextView textStorage] setAttributedString:[report autorelease]];
		
		[self beginReportPanel:self];
	}
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
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	[defaults synchronize];
	[self endPreferencesPanel];
}

- (IBAction) beginReportPanel:(id)sender
{
	[NSApp beginSheet:Report
	   modalForWindow:[NSApp mainWindow]
		modalDelegate:self
	   didEndSelector:NULL 
		  contextInfo:nil];
}

- (void) endReportPanel
{
	[Report orderOut:self];
	[NSApp endSheet:Report];
}

- (IBAction) reportOKButtonAction:(id)sender
{
	[self endReportPanel];
}

- (IBAction) verboseButtonAction:(id)sender
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	if([sender state] == 1){
		verbose = TRUE;
		[verboseButton setState:1];
		[verboseButton2 setState:1];
		verbose = TRUE;
	}
	else if([sender state] == 0){
		verbose = FALSE;
		[verboseButton setState:0];
		[verboseButton2 setState:0];
		verbose = FALSE;
	}
	
	[defaults setBool:verbose forKey:@"verbose"];
	[defaults synchronize];
}

-(IBAction) beginMemoryInfoPanel:(id)sender
{
	[self updateMemoryInfoPanel:self];
	[NSApp beginSheet:MemoryInfo
	   modalForWindow:[NSApp mainWindow]
		modalDelegate:self
	   didEndSelector:NULL
		  contextInfo:nil];	
}

- (void) showMemoryInfoPanel
{
	[self beginMemoryInfoPanel:self];
}
-(IBAction) endMemoryInfoPanel:(id)sender
{
	[MemoryInfo orderOut:self];
    [NSApp endSheet:MemoryInfo];
}

-(IBAction) infoOKButtonAction:(id)sender
{
	[self endMemoryInfoPanel:(id)sender];
}

- (IBAction) updateMemoryInfoPanel:(id)sender
{

}

- (IBAction) slotImageViewAction:(id)sender
{

	// update info for infoSlotTextField, infoSizeTextField, infoSpeedTextField, infoStatusTextField, infoTypeTextField
	[infoSlotTextField setStringValue:[[memoryInfo objectAtIndex:[sender tag]] objectForKey:@"_name"]];
	[infoSizeTextField setStringValue:[[memoryInfo objectAtIndex:[sender tag]] objectForKey:@"dimm_size"]];
	[infoSpeedTextField setStringValue:[[memoryInfo objectAtIndex:[sender tag]] objectForKey:@"dimm_speed"]];
	[infoStatusTextField setStringValue:[[memoryInfo objectAtIndex:[sender tag]] objectForKey:@"dimm_status"]];
	[infoTypeTextField setStringValue:[[memoryInfo objectAtIndex:[sender tag]] objectForKey:@"dimm_type"]];

	NSLog(@"Sender tag: %i", [sender tag]);
}

- (IBAction) quitAllButtonAction:(id)sender
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	quitAll = [sender state];
	
	if (quitAll){
        [quitFinderButton setEnabled:YES];
		[quitAllButton setState:1];
	}
	else
	{
		[quitFinderButton setEnabled:NO];
		[quitAllButton setState:0];
		[quitFinderButton setState:0];
		quitFinder = FALSE;
	}
	
	[defaults setBool:quitAll forKey:@"quitAll"];
	[defaults setBool:quitFinder forKey:@"quitFinder"];
	[defaults synchronize];
}

- (IBAction) quitFinderButtonAction:(id)sender
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	quitFinder = [sender state];
	
	if (quitFinder)
		[quitFinderButton setState:1];
	else
		[quitFinderButton setState:0];
	
	[defaults setBool:quitFinder forKey:@"quitFinder"];
	[defaults synchronize];
}


- (IBAction) maxButtonAction:(id)sender
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	maxLoops = [sender state];
	
	if (maxLoops){
        [loopTextField setEnabled:NO];
		[loopTextField setStringValue:@"255"];
		[loopsTextField setStringValue:@"255"];
	}
	else
	{
        [loopTextField setEnabled:YES];
		[loopTextField setStringValue:[[defaults objectForKey:@"totalLoops"] stringValue]];
		[loopsTextField setStringValue:[[defaults objectForKey:@"totalLoops"] stringValue]];
	}
	
	[defaults setBool:maxLoops forKey:@"maxLoops"];
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
	
	if(![remberTask isRunning]){
		amount = [amountTextField intValue];
	}
	
	[defaults setObject:[NSNumber numberWithInt:amount] forKey:@"amount"];
	[defaults synchronize];
}

-(IBAction)loopTextFieldAction:(id)sender
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

	if(![remberTask isRunning]){
		[loopsTextField setStringValue:[loopTextField stringValue]];
		totalLoops = [loopTextField intValue];
		[testProgress setMaxValue:(totalLoops * ([testList count] + 1))];
	}
	
	[defaults setObject:[NSNumber numberWithInt:totalLoops] forKey:@"totalLoops"];
	[defaults synchronize];
}


- (IBAction) errorButtonAction:(id)sender
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	continueOnError = [sender state];
	
	[defaults setBool:continueOnError forKey:@"continueOnError"];
	[defaults synchronize];
}

- (IBAction) reportButtonAction:(id)sender
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	showReport = [sender state];
	
	[defaults setBool:showReport forKey:@"showReport"];
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

- (IBAction) reportSaveButtonAction:(id)sender
{
	NSString* filename;
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setRequiredFileType:@"txt"];
	[panel setCanSelectHiddenExtension:YES];
	[panel setExtensionHidden:NO];
    if ([panel runModal] == NSOKButton) {
		filename = [NSString stringWithString:[panel filename]];
		[[[reportTextView textStorage] string] writeToFile:filename atomically:YES];
	}
}

- (IBAction)testButtonAction:(id)sender
{
	if(![remberTask isRunning]){
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
		totalLoops = [loopTextField intValue];
		loopsString = [NSString stringWithString:[loopTextField stringValue]];
		[loopsTextField setStringValue:loopsString];
		
		// update progress indicator with new loop values
		[testProgress setMaxValue:(totalLoops * ([testList count] + 1))];
		
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
			[statusTextField setStringValue:NSLocalizedString(@"Testing", @"Testing...")];
		}
		else
		{
			[statusTextField setStringValue:@"An error occurred during initialization."];
		}
	}
	else
	{
		// the 'stop' button was clicked.  terminate task.
		[remberTask stopProcess];
	}
}

- (IBAction) memoryInfoButtonAction:(id)sender
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	showMemoryInfo = [sender state];
	
	[memoryInfoButton setState:showMemoryInfo];
	[memoryInfoButton2 setState:showMemoryInfo];
	[defaults setBool:showMemoryInfo forKey:@"showMemoryInfo"];
	[defaults synchronize];
}


#pragma mark TaskWrapper Controller tasks

-(int) openTask:(NSString*)path withArguments:(NSArray*)arguments
{
	// Variables
	int processID = 0;
	NSMutableArray *args = [NSMutableArray arrayWithCapacity:1];
	
	// Set launch arguments
	[args addObject:path];
	[args addObjectsFromArray:arguments];
	
	// If the task is already running, release
	if ([remberTask isRunning]){
		[remberTask stopProcess];
        [remberTask release];
	}
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
	
	if(output != nil){
		// variables
		int i = 0;
		BOOL display = YES;
		NSMutableString *temp = [[NSMutableString alloc] init];
		
		
		// determine if we're in verbose mode
		if(!verbose){
			// determine if the output is CLI 'garbage'
			//
			// if the string doesn't match progress junk strings, 
			//		continue.
			NSEnumerator *enumerator = [progressList objectEnumerator];
			id object;
			while (object = [enumerator nextObject])
			{
				NSRange range = [output rangeOfString:object];
				if(range.location != NSNotFound)
					display = NO;		// if the output is junk, return without displaying
			}
		}
		
		NSRange range = [output rangeOfString:@"Memtest version"];
		if(range.location != NSNotFound){
			display = YES;
			temp = [NSString stringWithString:[[[[output componentsSeparatedByString:@"Allocated memory: "] objectAtIndex:1] componentsSeparatedByString:@"MB ("] objectAtIndex:0]];
			[reportDict setObject:temp forKey:@"allocatedAmount"];
			
			temp = [NSString stringWithString:[[[[output componentsSeparatedByString:@"Available memory: "] objectAtIndex:1] componentsSeparatedByString:@"MB ("] objectAtIndex:0]];
			[reportDict setObject:temp forKey:@"availableAmount"];
			
		}
	
		// Get test sequence string, increase loopsCompleted number
		range = [output rangeOfString:@"Test sequence"];
		if(range.location != NSNotFound){
			display = YES;
			loopsCompleted++;
			NSLog(@"Detected test sequence: %d", loopsCompleted);
			[loopsCompletedTextField setStringValue:[[NSNumber numberWithInt:(loopsCompleted - 1)] stringValue]];
		}
		
		// use scanner to determine which test is being run (if any),
		//	and display information in statusTextField
		
		NSEnumerator *enumerator = [testList objectEnumerator];	
		id object;
		i = 1;
		while(object = [enumerator nextObject]){
			range = [output rangeOfString:object];
			if(range.location != NSNotFound){
				if(!maxLoops)
					[testProgress setDoubleValue:((loopsCompleted - 1) * ([testList count] + 1) + i)];
				[statusTextField setStringValue:[NSLocalizedString(@"Running", @"Running test: ") stringByAppendingString:[testList objectAtIndex:(i-1)]]];
				//NSLog(@"Detected test: %@", [testList objectAtIndex:i]);
				display = YES;
				break;
			}
			else
				i++;
		}

		// Get 'All tests passed' string.  Re-assure user of tests passing.
		range = [output rangeOfString:@"All tests passed!"];
		if(range.location != NSNotFound)
		{
			display = YES;
			if([maxButton state] != 1){
				loopsCompleted++;
				[loopsCompletedTextField setStringValue:[[NSNumber numberWithInt:(loopsCompleted - 1)] stringValue]];
			}
			[reportDict setObject:@"All tests passed!" forKey:@"testResults"];
			[statusTextField setStringValue:NSLocalizedString(@"Passed", @"All tests passed!")];
		}
		
		// Get 'FAILED!' string for legacy versions of memtest.
		range = [output rangeOfString:@"FAILURE!"];
		if(range.location != NSNotFound)
		{
			display = YES;
			[statusTextField setStringValue:NSLocalizedString(@"Failure", @"FAILURE - see log for more info")];
			if([errorButton state] != 1){
				[remberTask stopProcess];
				NSRunAlertPanel(@"Rember", NSLocalizedString(@"Errors", @"Errors were detected.  See log for more details."), @"OK", @"", @"");
			}
			[reportDict setObject:@"FAILURE!" forKey:@"testResults"];
		}
		
		// Get '*** Address Test Failed ***' string for legacy versions of memtest. 
		range = [output rangeOfString:@"*** Address Test Failed ***"];
		if(range.location != NSNotFound)
		{
			display = YES;
			[statusTextField setStringValue:NSLocalizedString(@"Failure", @"FAILURE - see log for more info")];
			if([errorButton state] != 1){
				[remberTask stopProcess];
				NSRunAlertPanel(@"Rember", NSLocalizedString(@"Errors", @"Errors were detected.  See log for more details."), @"OK", @"", @"");
			}
			[reportDict setObject:output forKey:@"testResults"];
		}
		
		// Get '*** Memory Test Failed ***' string for newer versions of memtest. 
		range = [output rangeOfString:@"*** Memory Test Failed ***"];
		if(range.location != NSNotFound)
		{
			display = YES;
			[statusTextField setStringValue:NSLocalizedString(@"Failure", @"FAILURE - see log for more info")];
			if([errorButton state] != 1){
				[remberTask stopProcess];
				NSRunAlertPanel(@"Rember", NSLocalizedString(@"Errors", @"Errors were detected.  See log for more details."), @"OK", @"", @"");
			}
			[reportDict setObject:@"*** Memory Test Failed ***" forKey:@"testResults"];
		}
		
		// Get 'Execution time:' string.
		range = [output rangeOfString:@"Execution time:"];
		if(range.location != NSNotFound){
			display = YES;
			NSScanner *outputScanner = [NSScanner scannerWithString:output];
			if([outputScanner scanUpToString:@"seconds." intoString:&temp])
				[reportDict setObject:temp forKey:@"executionTime"];
			
		}
		
		
		// none of the progress phrases were found, or we are in verbose mode.  Display output
		// add the string (a chunk of the results from locate) to the NSTextView's
		// backing store, in the form of an attributed string
		
		if(display)
			[[testLog textStorage] appendAttributedString: [[[NSAttributedString alloc]
								initWithString: output] autorelease]];
		// setup a selector to be called the next time through the event loop to scroll
		// the view to the just pasted text.  We don't want to scroll right now,
		// because of a bug in Mac OS X version 10.1 that causes scrolling in the context
		// of a text storage update to starve the app of events
		[self performSelector:@selector(scrollToVisible:) withObject:nil afterDelay:0];
		
		
		temp = nil;
		[temp release];
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

	// disable other user controls while testing
	[loopTextField setEnabled:NO];
	[amountTextField setEnabled:NO];
	[maxButton setEnabled:NO];
	[memoryMatrix setEnabled:NO];
	[quitAllButton setEnabled:NO];
	[quitFinderButton setEnabled:NO];
	
    // clear the results
    [testLog setString:@""];
	[statusTextField setStringValue:NSLocalizedString(@"Initializing", @"Initializing status")];
	
	[testProgress setUsesThreadedAnimation:TRUE];
	
	[testProgress setIndeterminate:TRUE];
	[testProgress startAnimation:self];
		
    // change the "Test" button to say "Stop"
    [testButton setTitle:NSLocalizedString(@"Stop", @"Stop button value")];
	
	[reportDict setObject:[[NSDate date] description] forKey:@"startTime"];

	if(!maxLoops && ([loopsTextField doubleValue] >= 1) && ([loopsTextField doubleValue] < 256)){
			[testProgress setIndeterminate:FALSE];
			[testProgress setMinValue:0];
			[testProgress setMaxValue:([loopTextField doubleValue] * ([testList count] + 1))];
			[testProgress setDoubleValue:1];
	}
	else
	{
		// there was a loop related error (set to 0 or higher than 255) - inform user?
		
	}
	
}

// A callback that gets called when a TaskWrapper is completed, allowing us to do any cleanup
// that is needed from the app side.  This method is implemented as a part of conforming
// to the ProcessController protocol.
- (void)processFinished
{

    remberRunning=NO;
	
	[testProgress setIndeterminate:YES];
	[testProgress startAnimation:self];
	
	//[statusTextField setStringValue:NSLocalizedString(@"Idle", @"Status Idle")];
    
	// change the button's title back for the next search
    [testButton setTitle:NSLocalizedString(@"Test", @"Test button value")];
	
	//re-enable user controls (to pre-test state)
	if([maxButton state] == 1)
		[loopTextField setEnabled:NO];
	else
		[loopTextField setEnabled:YES];
	if([allButton state] == 1)
		[amountTextField setEnabled:NO];
	else
		[amountTextField setEnabled:YES];
	[maxButton setEnabled:YES];
	[memoryMatrix setEnabled:YES];
	[quitAllButton setEnabled:YES];
	if([quitAllButton state] == 1){
		[quitFinderButton setEnabled:YES];
	}
	
	terminationStatus = [remberTask terminationStatus];
	
	if((terminationStatus != 0) && (terminationStatus != 15))
	{
		NSRunAlertPanel(@"Rember", NSLocalizedString(@"Errors", @"Errors detected dialog box"), @"OK", @"", @"");
	}
	
	// set report values
	[reportDict setObject:[[NSNumber numberWithInt:[loopsCompletedTextField intValue]] stringValue] forKey:@"loopsCompleted"];
	[reportDict setObject:[[NSNumber numberWithInt:[loopsTextField intValue]] stringValue] forKey:@"loops"];
	[reportDict setObject:[NSString stringWithContentsOfFile:[NSHomeDirectory() stringByAppendingString:@"/Library/Preferences/net.kelleycomputing.Rember.builtInMemory.txt"]] forKey:@"builtInAmount"];

	if([allButton state] == 1)
		[reportDict setObject:@"All" forKey:@"requestedAmount"];
	else
		[reportDict setObject:[amountTextField stringValue] forKey:@"requestedAmount"];
	[reportDict setObject:[[NSDate date] description] forKey:@"stopTime"];

	[testProgress stopAnimation:self];

	[self showTestResults];
}

#pragma mark Other delegate methods

// If the user attempts to close the window, 
-(BOOL)windowShouldClose:(id)sender
{
	// quit when idle
	if(!remberRunning){
		[NSApp terminate:self];
		return YES;
	}
	else
	{
		int choice = NSAlertDefaultReturn;
		
		choice = NSRunAlertPanel(@"Rember",	NSLocalizedString(@"InProgress", @"Memory tests in progress"),NSLocalizedString(@"Cancel", @"Cancel button"), NSLocalizedString(@"OK", @"OK Button"), @"");
        if (choice == NSAlertDefaultReturn) { 
			/* Cancel termination */
            return NO;
        }
		else
		{
			[remberTask stopProcess];
			[NSApp terminate:self];
			return YES;
		}
	}
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app {
	// Determine if task is running...
    if ([remberTask isRunning]) {
        int choice = NSAlertDefaultReturn;
		
		choice = NSRunAlertPanel(@"Rember",	NSLocalizedString(@"InProgress", @"Memory tests in progress"),NSLocalizedString(@"Cancel", @"Cancel button"), NSLocalizedString(@"OK", @"OK Button"), @"");
        if (choice == NSAlertDefaultReturn) { 
			/* Cancel termination */
            return NSTerminateCancel;
        }
		else
		{
			[remberTask stopProcess];
		}
    }
    return NSTerminateNow;
}

- (void) dealloc
{
	if(memoryInfo != nil){[memoryInfo release]; memoryInfo = nil;}
	if(testList != nil){[testList release]; testList = nil;}
	if(progressList != nil){[progressList release]; progressList = nil;}
	if(reportDict != nil){[reportDict release]; reportDict = nil;}
	
	IODeregisterForSystemPower(&root_port);
	
	[super dealloc];
}

void callback(void *x,io_service_t y,natural_t messageType,void* messageArgument) 
{ 
	printf("messageType %08lx,arg %08lx\n",(long unsigned int)messageType, 
		   (long unsigned int)messageArgument); 
	switch(messageType){ 
		case kIOMessageSystemWillSleep: 
			// Handle demand sleep (such as  sleep caused by running out of 
			// batteries, closing the lid of a laptop, or selecting 
			// sleep from the Apple menu. 
			IOCancelPowerChange(root_port,(long)messageArgument); 
			NSLog(@"System Will Sleep");
			break; 
		case kIOMessageCanSystemSleep: 
			// In this case, the computer has been idle for several minutes 
			// and will sleep soon so you must either allow or cancel 
			// this notification. Important: if you don't respond, there will 
			// be a 30-second timeout before the computer sleeps. 
			// IOCancelPowerChange(root_port,(long)messageArgument); 
			IOCancelPowerChange(root_port,(long)messageArgument); 
			NSLog(@"Can System Sleep");
			break; 
		case kIOMessageSystemHasPoweredOn: 
			// Handle wakeup. 
			
			NSLog(@"System Has Powered On");
			break; 
		default:
			
			NSLog(@"Unrecognized Power Change Message");
			break;
	} 
} 		
#pragma mark TableView controls

-(int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [memoryInfo count];
}

// Stop the table's rows from being editable when we double-click on them
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row
{  
    return FALSE;
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex
{
	NSString  *ident;
    NSObject  *object;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
    ident = [aTableColumn identifier];
	
	if([ident isEqualToString:@"infoSlot"])
	{
		object = [[memoryInfo objectAtIndex:rowIndex] objectForKey:@"_name"];
	}
	else if([ident isEqualToString:@"infoSize"])
	{
		object = [[memoryInfo objectAtIndex:rowIndex] objectForKey:@"dimm_size"];

	}
	else if([ident isEqualToString:@"infoSpeed"])
	{
		object = [[memoryInfo objectAtIndex:rowIndex] objectForKey:@"dimm_speed"];

	}
	else if([ident isEqualToString:@"infoStatus"])
	{
		if([[[memoryInfo objectAtIndex:rowIndex] objectForKey:@"dimm_status"] isEqualToString:@"ok"]){
			object = [NSImage imageNamed:@"greenStatus.tiff"];
		}
		else if([[[memoryInfo objectAtIndex:rowIndex] objectForKey:@"dimm_status"] isEqualToString:@"failed"]){
			object = [NSImage imageNamed:@"redStatus.tiff"];
		}
		else if([[[memoryInfo objectAtIndex:rowIndex] objectForKey:@"dimm_status"] isEqualToString:@"empty"]){
			object = [NSImage imageNamed:@"whiteStatus.tiff"];
		}
		else{
			object = [NSImage imageNamed:@"whiteStatus.tiff"];
		}
	}
	else if([ident isEqualToString:@"infoType"])
	{
		object = [[memoryInfo objectAtIndex:rowIndex] objectForKey:@"dimm_type"];

	}

	return object;
}

- (void)tableView:(NSTableView *)aTableView	setObjectValue:anObject
   forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    return;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
	
}

@end
