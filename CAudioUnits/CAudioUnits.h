//
//  CAudioUnits.h
//  CAudioUnits
//
//  Created by CHARLES GILLINGHAM on 6/28/15.
//  Copyright (c) 2015 CharlesGillingham. All rights reserved.
//

//  A simple Objective-C interface to OSX's AudioUnits and AUGraph (with a lot of dumb-proofing)

#import <Foundation/Foundation.h>

//! Project version number for CAudioUnits.
FOUNDATION_EXPORT double CAudioUnitsVersionNumber;

//! Project version string for CAudioUnits.
FOUNDATION_EXPORT const unsigned char CAudioUnitsVersionString[];

#import <Foundation/Foundation.h>

#import <CAudioUnits/CAudioUnit.h>
#import <CAudioUnits/CAudioUnit+UI.h>
#import <CAudioUnits/CAUErrors.h>

// The four types of audio units supported by this interface.
#import  <CAudioUnits/CAudioGenerator.h>
#import  <CAudioUnits/CAudioInstrument.h>
#import  <CAudioUnits/CAudioEffect.h>
#import  <CAudioUnits/CAudioOutput.h>

// The remaining headers should not be needed by a simple application.

// If you need multiple signal chains in the same application, you need to use a separate CAUGraph for each signal chain. Create the graph first, and then create each unit with it. Units may only be connected to other units from the same graph.
#import <CAudioUnits/CAUGraph.h>

// A few basic examples, useful for demos and debugging.
#import <CAudioUnits/CAudioUnit+Examples.h>