/*
RemberController.m
 
RemberController class implementation.

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

#import "RemberController.h"

@implementation RemberController

- (void) awakeFromNib
{
	processID = 0;
	terminationStatus = 0;
}

- (IBAction) infiniteButtonAction:(id)sender
{
	if ([infiniteButton state] == 1){
        [loopTextField setEnabled:NO];
	}
	else
	{
        [loopTextField setEnabled:YES];
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

- (IBAction)testButtonAction:(id)sender
{
	if(!remberRunning){
		// variables
		NSString *loops, *amount;
		
		// determine number of loops to do
		if([infiniteButton state] == 1)
			loops = [NSString stringWithString:@""];
		else
			loops = [NSString stringWithString:[loopTextField stringValue]];
		
		// determine amount of memory to test
		if([allButton state] == 1)
			amount = [NSString stringWithString:@"all"];
		else
			amount = [NSString stringWithString:[amountTextField stringValue]];
		
		// open the memtest task and log it's processID
		processID = [self openTask:[[NSBundle mainBundle] pathForResource:@"memtest" ofType:nil] withArguments:[NSArray arrayWithObjects:amount, loops, nil]];
		
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
	// Scan for the following:
	//
	// testing 
	// sticking
	// -
	// /
	// \
	// |
	//	Random Value
	//	Compare XOR
	//	Compare SUB
	//	Compare MUL
	//	Compare DIV
	//	Compare OR
	//	Compare AND
	//	Sequential Increment
	//	Solid Bits
	//	Block Sequential
	//	Checkerboard
	//	Bit Spread
	//	Bit Flip
	//	Walking Ones
	//	Walking Zeroes
	//
	// this will determine whether or not to display the output
	
	//
	NSArray * testList = [NSArray arrayWithObjects:	
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
	
	NSArray * progressList = [NSArray arrayWithObjects:
		@"-", @"/", @"|", @"", nil];
		
	NSLog(output);
	
	if([output componentsSeparatedByString:[testList objectAtIndex:0]] == [testList objectAtIndex:0])
	{
		[statusTextField setStringValue:[testList objectAtIndex:0]];
	}
	if([output componentsSeparatedByString:[progressList objectAtIndex:0]] == [progressList objectAtIndex:0])
	{
		[statusTextField setStringValue:[progressList objectAtIndex:0]];
	}
	if([testList containsObject:output])
	{
		[statusTextField setStringValue:[testList objectAtIndex:[testList indexOfObject:output]]];
	}
	else if ([progressList containsObject:output])
	{
	// Don't display this output
	}
	else if([output hasPrefix:@"testing"] || [output hasPrefix:@"setting"])
	{
		[statusTextField setStringValue:output];
	}
	else
	{
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
    remberRunning = YES;
    // clear the results
    [testLog setString:@""];
	[statusTextField setStringValue:@"Testing..."];
	[testProgress startAnimation:self];
    // change the "Open" button to say "Stop"
    [testButton setTitle:@"Stop"];
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
}

// If the user closes the search window, let's just quit
-(BOOL)windowShouldClose:(id)sender
{
    [NSApp terminate:nil];
    return YES;
}

@end
