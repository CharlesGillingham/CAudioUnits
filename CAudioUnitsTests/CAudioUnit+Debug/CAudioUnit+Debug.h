//
//  CAudioUnit+Debug.h
//  CAudioUnits
//
//  Created by CHARLES GILLINGHAM on 6/25/15.
//  Copyright (c) 2015 Charles Gillingham. All rights reserved.
//

#import "CAudioUnit.h"
#import "CAUGraph.h"
#import "CAudioUnit+UI.h"
#import "CAUErrors.h"
#import "CAudioOutput.h"
#import "CAudioEffect.h"
#import "CAudioInstrument.h"
#import "CAudioGenerator.h"

@interface CAudioUnit (Debug)
+ (BOOL) test1;
+ (BOOL) test2;
+ (BOOL) testChangeEffect;
+ (BOOL) testSearch;
+ (BOOL) testLoadSave;
+ (BOOL) testMultipleManagers;
+ (BOOL) testErrors;
+ (BOOL) connectionsGridTest;
+ (BOOL) unitGridTest;
+ (BOOL) testInstrument;
+ (BOOL) UICrashTest;
@end
