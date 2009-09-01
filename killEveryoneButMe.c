/*
 *  killEveryoneButMe.c
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

#include "killEveryoneButMe.h"

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
