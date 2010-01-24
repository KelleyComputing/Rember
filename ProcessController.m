/*
 *  ProcessController.c
 *  Rember
 *
 *  Created by Eddie Kelley <eddie@kelleycomputing.net> on 9/12/04.
 *  Copyright 2004 KelleyComputing. All rights reserved.
 
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

#include "ProcessController.h"

@implementation ProcessController

// Quit every other application on the machine
-(void) quitAllProcessesAndFinder:(BOOL)quitFinderToo{
    ProcessSerialNumber nextProcessToKill = {kNoProcess, kNoProcess};
    ProcessSerialNumber finderPSN; //we need to record this since finder must be quit last.
    ProcessSerialNumber ourPSN; // we need to record this so that we don't quit ourselves
    OSErr error;
    ProcessInfoRec infoRec;
	Str31 processNameStr;
	CFStringRef processName;

    Boolean processIsFinder;
    Boolean processIsUs;
    Boolean specialMacOSXProcessWhichWeShouldNotKill;
    Boolean finderFound = false;
	
	GetCurrentProcess(&ourPSN);
	
    do
    {
        error = GetNextProcess(&nextProcessToKill);
        
        if (error == noErr)
        {
			SameProcess(&ourPSN, &nextProcessToKill, &processIsUs);
			
            // Make sure that we don't quit our process            
            if (!processIsUs)
            {
				CopyProcessName(&nextProcessToKill, &processName);
				
				NSLog(@"Got process:%@", processName);
				
				processIsFinder = FALSE;
				
				// First check to see if it's the Finder
				if (finderFound == FALSE)
				{
					if ([(NSString*)processName isEqualToString:@"Finder"]) 
					{
						NSLog(@"Got Finder");
						// save finder PSN for later
						finderPSN = nextProcessToKill;
						finderFound = TRUE;
						processIsFinder = TRUE;
					}
				}
				
				//we need to make sure we don't quit certain applications 
				if ([(NSString*)processName isEqualToString:@"loginwindow"])
				{
					NSLog(@"Not quitting loginwindow");
					//don't want to quit loginwindow on MacOSX or system will logout
					specialMacOSXProcessWhichWeShouldNotKill = TRUE;
				}
				else if ([(NSString*)processName isEqualToString:@"Dock"])
				{
					NSLog(@"Not quitting Dock");
					//don't want to quit Dock on MacOSX it provides important support (for example Command+Tab switching)
					specialMacOSXProcessWhichWeShouldNotKill = TRUE;
				}
				else if ([(NSString*)processName isEqualToString:@"SystemUIServer"])
				{
					NSLog(@"Not quitting SystemUIServer");
					//don't want to quit the SystemUI server on MacOSX this offers important system support
					specialMacOSXProcessWhichWeShouldNotKill = TRUE;
				}
				else
				{
					specialMacOSXProcessWhichWeShouldNotKill = FALSE; //this isn't a special process
				}
				
				if ((specialMacOSXProcessWhichWeShouldNotKill == FALSE) && (processIsFinder == FALSE))
				{
					NSLog(@"Quitting:%@", processName);
					
					error = [self quitProcessWithSerialNumber:nextProcessToKill];
					if(error)
						NSLog(@"Error:%d quitting process:%d", error, nextProcessToKill);
                }
				processName = nil;
            }
			else {
				NSLog(@"Not quitting ourselves");
			}

        }
    }
    while (error == noErr);
	
    /* Now, if the finder was running (and we want to quit it) then it's safe to kill it */
	/* Note: the Finder cannot be quit this way in 10.6 */
    if ((finderFound == TRUE) && (quitFinderToo == TRUE))
    {
        error = [self quitProcessWithSerialNumber:finderPSN];
		NSLog(@"Quitting Finder");
		if(error)
			NSLog(@"Error quitting Finder:%d", error);
    }
}   

-(OSErr) quitProcessWithSerialNumber:(ProcessSerialNumber)processToQuit{
	OSErr error;
	error = KillProcess(&processToQuit);
	
	return error;
}

@end
