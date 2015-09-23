//
//  CAudioUnit+Debug.m
//  CAudioUnits
//
//  Created by CHARLES GILLINGHAM on 6/25/15.
//  Copyright (c) 2015 CharlesGillingham. All rights reserved.

#import "CAudioUnit+Debug.h"
#import "CAudioUnit+Examples.h"
#import "CAudioUnit_Internal.h"
#import "CAudioUnit+Search.h"
#import "CAUGraph_Internal.h"
#import "CAudioNonModalAUGraph.h"
#import "AudioComponentDescription Names.h"
#import "CDebugMessages.h"
#import "CDebugSelfCheckingObject.h"

const char * CAudioUnitErrorString(OSStatus errCode);


#ifdef DEBUG

@interface CAUGraph ()
- (AUGraph) graph;
@end

@interface CAUGraph (Debug) <CDebugSelfCheckingObject>
- (BOOL) check;
@end

@implementation CAUGraph (Debug)

- (BOOL) check
{
    // Just make sure the graph is running
    Boolean isRunning;
    if (!CNOERR(AUGraphIsRunning(self.graph, &isRunning))) return NO;
    if (!CASSERT( isRunning )) return NO;
    return YES;
}


- (BOOL) areConnected: (CAudioUnit *) unit1 : (CAudioUnit *) unit2
{
    AUNode outNode;
    UInt32 inputBus;
    if (!CNOERR(AUGraphGetOutputConnection(self.graph, unit1.auNode, 0, &outNode, &inputBus))) return NO;
    
    if (unit1.outputUnit) {
        if (!CASSERT(unit1.outputUnit.auNode == outNode)) return NO;
    } else {
        if (!CASSERT(outNode == 0)) return NO;
    }
    return YES;
}


@end


extern NSUInteger CAudioUnit_count;

// --------------------------------------------------------------------------------------------------------------
//      CAudioUnit
// --------------------------------------------------------------------------------------------------------------


@implementation CAudioUnit (Debug)


- (BOOL) check
{
    return ([self.cauGraph check] &&
            [self checkType] &&
            [self checkOutput]);
}



- (BOOL) checkType
{
    // TOOD: Check that the typeNames match the classes, and the sub type names match the subtypes, etc: exercise all the search code (except the constructor, tested below).
    switch (self.auDescription.componentType) {
        case kAudioUnitType_Output: {
            if (!CASSERTEQUAL(self.typeName, kCAudioUnitTypeName_Output)) return NO;
            CASSERT_RET([self isKindOfClass:[CAudioOutput class]]);
            break;
        }
        case kAudioUnitType_Effect: {
            if (!CASSERTEQUAL(self.typeName, kCAudioUnitTypeName_Effect)) return NO;
                
            CASSERT_RET([self isKindOfClass:[CAudioEffect class]]);
            break;
        }
        case kAudioUnitType_Generator: {
            if (!CASSERTEQUAL(self.typeName, kCAudioUnitTypeName_Generator)) return NO;
            CASSERT_RET([self isKindOfClass:[CAudioGenerator class]]);
            break;
        }
        case kAudioUnitType_MusicDevice: {
            if (!CASSERTEQUAL(self.typeName, kCAudioUnitTypeName_Instrument)) return NO;
            CASSERT_RET([self isKindOfClass:[CAudioInstrument class]]);
            break;
        }
        default: {
            CFAIL(@"Unknown audio unit subclass");
            return NO;
        }
    }
    
    AudioComponentDescription acd;
    CASSERT_RET((ACDFromOSTypeAndSubtypeName(self.auDescription.componentType, self.subtypeName, &acd) == 0));
    CASSERT_RET(acd.componentType == self.auDescription.componentType);
    CASSERT_RET(acd.componentSubType == self.auDescription.componentSubType);
    if (!CASSERTEQUAL(self.subtypeName, ACDSubtypeName(acd))) return NO;
    
    return YES;
}


- (BOOL) checkOutput
{
    return [CAudioUnit checkConnection:self:self.outputUnit];
}


+ (BOOL) checkConnection: (CAudioUnit *) unit1 : (CAudioUnit *) unit2
{
    if (!unit1) return YES;
    CASSERT_RET([unit1 isKindOfClass:[CAudioUnit class]]);
    if (![unit1 checkType]) return NO;
    if (![unit1.cauGraph check]) return NO;
    
    if (unit2) {
        CASSERT_RET([unit2 isKindOfClass:[CAudioUnit class]]);
        CASSERT_RET(unit2.cauGraph == unit1.cauGraph);
    }
    
    CASSERT_RET(unit1.outputUnit == unit2);
    if (unit2) CASSERT_RET(unit2.inputUnit == unit1);
    
    // Show that the unit has the same connections inside AUGraph as the "outputUnit" pointer suggests.
    return [unit1.cauGraph areConnected:unit1:unit2];
}


+ (BOOL) checkGraph: (NSUInteger) count
                   : (CAudioUnit *) unit1
                   : (CAudioUnit *) unit2
                   : (CAudioUnit *) unit3
                   : (CAudioUnit *) unit4
                   : (CAudioUnit *) unit5
                   : (CAudioUnit *) unit6
{
    if (count < 1) { CASSERT_RET(unit1 == nil); } else { CASSERT_RET(unit1 != nil); }
    if (count < 2) { CASSERT_RET(unit2 == nil); } else { CASSERT_RET(unit2 != nil); }
    if (count < 3) { CASSERT_RET(unit3 == nil); } else { CASSERT_RET(unit3 != nil); }
    if (count < 4) { CASSERT_RET(unit4 == nil); } else { CASSERT_RET(unit4 != nil); }
    if (count < 5) { CASSERT_RET(unit5 == nil); } else { CASSERT_RET(unit5 != nil); }
    if (count < 6) { CASSERT_RET(unit6 == nil); } else { CASSERT_RET(unit6 != nil); }
    
    return ([CAudioUnit checkConnection: unit1 : unit2] &&
            [CAudioUnit checkConnection: unit2 : unit3] &&
            [CAudioUnit checkConnection: unit3 : unit4] &&
            [CAudioUnit checkConnection: unit4 : unit5] &&
            [CAudioUnit checkConnection: unit5 : unit6] &&
            [CAudioUnit checkConnection: unit6 : nil]);
}



+ (BOOL) checkGraph: (NSUInteger) count
                   : (CAudioUnit *) unit1
                   : (CAudioUnit *) unit2
                   : (CAudioUnit *) unit3
{
    return [self checkGraph:count:unit1:unit2:unit3:nil:nil:nil];
}



+ (BOOL) checkDeallocation: (NSUInteger) n
{
    if (CAudioUnit_count > n) {
        printf("CAudio Units stranded.\n");
    } else if (CAudioUnit_count < n) {
        printf("CAudio Units missing.\n");
    }
    
    return CASSERTEQUAL(CAudioUnit_count,0);
}



// --------------------------------------------------------------------------------------------------------------
//      TESTS
// --------------------------------------------------------------------------------------------------------------


BOOL CAudioUnitCheckError(OSStatus expectedError)
{
    BOOL fOk = YES;
    OSStatus currentErrCode;
    if (CAudioUnit_currentError) {
        currentErrCode = (OSStatus) CAudioUnit_currentError.code;
    } else {
        currentErrCode = 0;
    }
    
    if (expectedError != currentErrCode) {
        printf("Expected error: %ld %s\n", (long)expectedError, CAudioUnitErrorString(expectedError));
        printf("Got error: %ld %s\n", (long)currentErrCode, CAudioUnitErrorString(currentErrCode));
        CASSERT_IN_C(expectedError == currentErrCode);
        fOk = NO;
    }
    CAudioUnit_currentError = nil;
    return fOk;
}


#define expectAnError(expectedError, action) \
printf("\n\nIGNORE FOLLOWING ERRORS:>>>>>>>>>\n"); \
CAudioUnit_currentError = nil; \
action; \
printf("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n"); \
if (!CAudioUnitCheckError(expectedError)) return NO; \

#define CheckNoErr   if (!(CAudioUnitCheckError(0))) return NO

// --------------------------------------------------------------------------------------------------------------
//      TESTS
// --------------------------------------------------------------------------------------------------------------



+ (BOOL) test1
{
    CAudioUnit_count = 0;
    CAudioUnit_currentError = nil;
    @autoreleasepool {
        CAUGraph          * graph       = [CAUGraph new];
        CAudioOutput      * outputUnit  = [CAudioOutput defaultOutput:graph];
        CAudioGenerator   * filePlayer  = [CAudioGenerator filePlayer:graph];
        filePlayer.outputUnit = outputUnit;
        
        printf("\n\n\n\n\nOUTPUT NAME:<%s>\n\n\n\n\n\n\n", outputUnit.subtypeName.UTF8String);
                
        if (!(CAudioUnitCheckError(0))) return NO;
        if(![CAudioUnit checkGraph:2 : filePlayer : outputUnit : nil]) return NO;
    }
    
    // 1 because the outputNode is persistent. But why doesn't the manager free itself??
    if (![CAudioUnit checkDeallocation:0]) return NO;
    return YES;
}



// Another crash test, with an effect, looking up the names this time, using the singleton graph and using a different order
+ (BOOL) test2
{
    CAudioUnit_count = 0;
    @autoreleasepool {
        CAudioEffect    * effect      = [[CAudioEffect alloc] initWithSubtype:@"Apple: AUDelay"];
        CAudioGenerator * filePlayer  = [[CAudioGenerator alloc] initWithSubtype:@"Apple: AUAudioFilePlayer"];
        CAudioOutput    * outputUnit  = [[CAudioOutput alloc] initWithSubtype:@"Apple: DefaultOutputUnit"];
        filePlayer.outputUnit = effect;
        effect.outputUnit = outputUnit;
        
        if (!(CAudioUnitCheckError(0))) return NO;
        if(![CAudioUnit checkGraph:3: filePlayer : effect : outputUnit]) return NO;
    }
    if (![CAudioUnit checkDeallocation:0]) return NO;
    return YES;
}



+ (BOOL)  testChangeEffect
{
    CAudioUnit_count = 0;
    @autoreleasepool {
        CAUGraph        * graph       = [CAUGraph new];
        CAudioOutput    * outputUnit  = [CAudioOutput defaultOutput:graph];
        CAudioEffect    * delay       = [CAudioEffect delay:graph];
        CAudioEffect    * pitch       = [CAudioEffect pitch:graph];
        CAudioGenerator * filePlayer  = [CAudioGenerator filePlayer:graph];
       
        filePlayer.outputUnit = pitch;
        pitch.outputUnit = outputUnit;
        
        pitch.outputUnit = nil;
        
        filePlayer.outputUnit = delay;
        delay.outputUnit = outputUnit;
        
        if (!(CAudioUnitCheckError(0))) return NO;
        if(![CAudioUnit checkGraph:3: filePlayer : delay : outputUnit]) return NO;
    }
    if (![CAudioUnit checkDeallocation:0]) return NO;
    return YES;
}


// -------------------------------------------------------------------------------------------------------
//      FEATURE TESTS
// -------------------------------------------------------------------------------------------------------


+ (BOOL) testSearch
{
    CAudioUnit_count = 0;
    @autoreleasepool {
        CAUGraph * graph = [CAUGraph new];
        CAudioUnit * outputUnit  = [CAudioUnit unitWithType:kCAudioUnitTypeName_Output
                                                    subtype: @"Apple: DefaultOutputUnit"
                                                      graph: graph];
       CAudioUnit * filePlayer = [CAudioUnit unitWithType:kCAudioUnitTypeName_Generator
                                                   subtype: @"Apple: AUAudioFilePlayer"
                                                      graph: graph];
        CAudioUnit * delay      = [CAudioUnit unitWithType:kCAudioUnitTypeName_Effect
                                                   subtype: @"Apple: AUDelay"
                                                      graph: graph];
        
        filePlayer.outputUnit = delay;
        delay.outputUnit = outputUnit;
        
        if (!(CAudioUnitCheckError(0))) return NO;
        if(![CAudioUnit checkGraph:3 : filePlayer : delay : outputUnit]) return NO;
    }
    if (![CAudioUnit checkDeallocation:0]) return NO;
    
    
    @autoreleasepool {
        CAUGraph * graph = [CAUGraph new];
  
        CAudioUnit * filePlayer;
        
        expectAnError(kCAudioUnitsErr_unknownType,
                      filePlayer = [CAudioUnit unitWithType:@"not a type"
                                                    subtype:@"not a subtype"
                                                       graph:graph];
                      );
        
        expectAnError(kCAudioUnitsErr_unknownSubtype,
                      filePlayer = [CAudioUnit unitWithType:kCAudioUnitTypeName_Generator
                                                    subtype:@"not a subtype"
                                                       graph:graph];
                      );
    }
    if (![CAudioUnit checkDeallocation:0]) return NO;
    
    return YES;
}


+ (BOOL)  testLoadSave
{
    CAudioUnit_count = 0;
    NSMutableData   * data  = [NSMutableData data];
    @autoreleasepool {
        CAUGraph        * graph      = [CAUGraph new];
        CAudioOutput    * outputUnit = [CAudioOutput defaultOutput:graph];
        CAudioGenerator * filePlayer = [CAudioGenerator filePlayer:graph];
        filePlayer.outputUnit = outputUnit;
        if(![CAudioUnit checkGraph: 2: filePlayer : outputUnit : nil]) return NO;
        
        NSKeyedArchiver * coder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [coder encodeObject:filePlayer forKey:@"File player"];
        [coder encodeObject:outputUnit forKey:@"Output unit"];
        [coder finishEncoding];
        
    }
    if (![CAudioUnit checkDeallocation:0]) return NO;
    
    @autoreleasepool {
        NSKeyedUnarchiver * decoder;
        decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData: data];
        
       CAudioUnit * f,* o;
        @try {
            f = [decoder decodeObjectForKey:@"File player"];
            o = [decoder decodeObjectForKey:@"Output unit"];
            
        }
        @catch (NSException *except) {
            printf("FAILED:\n%s\n",[[except description] UTF8String]);
            [except raise];
        }
        [decoder finishDecoding];
        
        if (!(CAudioUnitCheckError(0))) return NO;
        if(![CAudioUnit checkGraph:2: f : o : nil]) return NO;
    }
    if (![CAudioUnit checkDeallocation:0]) return NO;

    return YES;
}


+ (BOOL)  testMultipleManagers
{
    CAudioUnit_count = 0;
    @autoreleasepool {
        CAUGraph        * g1           = [CAUGraph new];
        CAudioOutput    * outputUnit1  = [CAudioOutput defaultOutput:g1];
        CAudioEffect    * delay1       = [CAudioEffect delay:g1];
        CAudioGenerator * filePlayer1  = [CAudioGenerator filePlayer:g1];
        CAUGraph        * g2           = [CAUGraph new];
        CAudioOutput    * outputUnit2  = [CAudioOutput defaultOutput:g2];
        CAudioGenerator * filePlayer2  = [CAudioGenerator filePlayer:g2];
        
        filePlayer1.outputUnit = delay1;
        delay1.outputUnit = outputUnit1;
        
        filePlayer2.outputUnit = outputUnit2;
        
        if (!(CAudioUnitCheckError(0))) return NO;
        
        if (![CAudioUnit checkGraph:3:filePlayer1:delay1:outputUnit1]) return NO;
        if (![CAudioUnit checkGraph:2:filePlayer2:outputUnit2:nil]) return NO;
        
        expectAnError(kAUGraphErr_InvalidConnection,
                      filePlayer2.outputUnit = delay1);
        
        expectAnError(kAUGraphErr_InvalidConnection,
                      filePlayer1.outputUnit = outputUnit2);
 
        if (![CAudioUnit checkGraph:3:filePlayer1:delay1:outputUnit1]) return NO;
        if (![CAudioUnit checkGraph:2:filePlayer2:outputUnit2:nil]) return NO;
    }
    
    if (![CAudioUnit checkDeallocation:0]) return NO;
    return YES;
}



+ (BOOL)  testErrors
{
    @autoreleasepool {
        CAudioUnit_count = 0;
        CAudioOutput * outputUnit;
        CAudioUnit * filePlayer, * delay;
        CAudioUnit_count = 0;
        
        CAUGraph * g = [CAUGraph new];
        
        expectAnError(kCAudioUnitsErr_unknownSubtype,
                      outputUnit = [[CAudioOutput alloc ]initWithSubtype:@"not a output unit type" graph:g]);
        if (!CASSERT(outputUnit == nil)) return NO;
        outputUnit  = [CAudioOutput defaultOutput:g];
        
        expectAnError(kCAudioUnitsErr_unknownSubtype,
                      delay = [[CAudioEffect alloc] initWithSubtype:@"not an effet type" graph:g]);
        if (!CASSERT(delay == nil)) return NO;
        delay       = [CAudioEffect delay:g];
       
        // Sending to the wrong class
        expectAnError(kCAudioUnitsErr_unknownSubtype,
                      filePlayer = [[CAudioGenerator alloc] initWithSubtype:@"Apple: DefaultOutputUnit" graph:g]);
        if (!CASSERT(filePlayer == nil)) return NO;
        filePlayer  = [CAudioGenerator filePlayer:g];
        
        filePlayer.outputUnit = delay;
        delay.outputUnit = outputUnit;
        if (!(CAudioUnitCheckError(0))) return NO;
        
        expectAnError(kAUGraphErr_InvalidConnection,
                      outputUnit.outputUnit = filePlayer);
        expectAnError(kAUGraphErr_InvalidAudioUnit,
                      filePlayer.outputUnit = (CAudioUnit *) @"Not an audio unit");
        expectAnError(kAUGraphErr_InvalidConnection,
                      filePlayer.outputUnit = filePlayer);
        expectAnError(kAUGraphErr_InvalidConnection,
                      delay.outputUnit = filePlayer);
        
        if (![CAudioUnit checkGraph:3:filePlayer:delay:outputUnit]) return NO;
    }
    
    if (![CAudioUnit checkDeallocation:0]) return NO;
    return YES;
}


// We can't check if the device is accurately rendering audio, but we can test if it will just take a message and not crash.
+ (BOOL) testInstrument
{
    @autoreleasepool {
        CAUGraph          * graph       = [CAUGraph new];
        CAudioOutput      * outputUnit  = [CAudioOutput defaultOutput:graph];
        CAudioInstrument  * synth       = [CAudioInstrument DLSSynth:graph];
        synth.outputUnit                = outputUnit;
        
        // Note on, channel 0, middle C, velocity = 80
        UInt8 msg[3] = {0x90,60,80};
        
        [synth respondToMIDI:msg ofSize:3];
    }
    return YES;
    
}



// ---------------------------------------------------------------------------------------------------------------------
// Grid test 1: all possible connections & connection failures
// ---------------------------------------------------------------------------------------------------------------------
// This test tries every possible new connection between a generator, an effect, and an outputUnit, given any possible set of current connections. I.e. Every possible action is tried on every possible graph.
// This is primarily a test of non-modality: the current state after each failure should remain unchanged, and the graph should always continue to run. (Note: this will print one comparison as a possible error, but if you examine it, you'll see that it has just reversed the order it prints the connections).
// There are 5 states of the graph. <Empty>  FP=>Delay  FP=>Output  Delay=>Output  FP=>Delay=>Output

// There are 12 possible connection actions from each state (each of the three X each of the three + nil). 6 are illegal, an that leaves these six:
// (1) filePlayer.outputUnit = nil
// (2) filePlayer.outputUnit = delay
// (3) filePlayer.outputUnit = output
// (4) delay.outputUnit = nil
// (5) delay.outputUnit = output
// (6) output.outputUnit = nil  (always trivial)
// Three out of these six are trivial (because they reset the graph to the same graph).
// We will test the trivial and error cases in "connect test"

// So, from every graph, there are three transitions we need to test.

// These are 15 possible possible transitions
// <Empty>    ---->  FP=>Delay
// <Empty>    ---->  FP=>Output
// <Empty>    ---->  Delay=>Output
// FP=>Delay  ---->  <Empty>
// FP=>Delay  ---->  FP=>Output
// FP=>Delay  ---->  FP=>Delay=>Output
// FP=>Output ---->  <Empty>
// FP=>Output ---->  FP=>Delay
// FP=>Output ---->  Delay=>Output
// Delay=>Out ---->  FP=>Delay=>Out
// Delay=>Out ---->  FP=>Out
// Delay=>Out ---->  <Empty>
// FP=>D=>Out ---->  Delay=>Out
// FP=>D=>Out ---->  FP=>Out
// FP=>D=>Out ---->  FP=>D

// So, do them in this order (this transition graph is  "Konigsberg Bridge" graph ... )
// <Empty>    ---->  FP=>D
// FP=>D      ---->  FP=>D=>Out
// FP=>D=>Out ---->  FP=>D
// FP=>D      ---->  <Empty>
// <Empty>    ---->  D=>Out
// D=>Out     ---->  FP=>D=>Out
// FP=>D=>Out ---->  D=>Out
// D=>Out     ---->  Empty
// <Empty>    ---->  FP=>Out
// FP=>Out    ---->  FP=>D
// FP=>D      ---->  FP=>Out
// FP=>Out    ---->  D=>Out
// D=>Out     ---->  <Empty>
// BUILD F=>D=>Out
// FP=>D=>Out ----> FP=>Out


+ (BOOL) connectionsGridTest
{
    CAudioUnit_count = 0;
    @autoreleasepool {
        CAudioUnit_currentError = nil;
        CAUGraph        * graph      = [CAUGraph new];
        CAudioOutput    * outputUnit = [CAudioOutput    defaultOutput:graph];
        CAudioEffect    * delay      = [CAudioEffect    delay:        graph];
        CAudioGenerator * filePlayer = [CAudioGenerator filePlayer:   graph];
    
        if (!(CAudioUnitCheckError(0))) return NO;
        if (![self connectTest: filePlayer: delay: outputUnit:0:nil:nil:nil]) return NO;
        
        // <Empty>    ---->  FP=>D
        filePlayer.outputUnit = delay;
        if (![self connectTest: filePlayer: delay: outputUnit:2:filePlayer: delay: nil]) return NO;
        
        // FP=>D      ---->  FP=>D=>Out
        delay.outputUnit = outputUnit;
        if (![self connectTest: filePlayer: delay: outputUnit:3:filePlayer: delay: outputUnit]) return NO;
        
        // FP=>D=>Out ---->  FP=>D
        delay.outputUnit = nil;
        if (![self connectTest: filePlayer: delay: outputUnit:2:filePlayer: delay: nil]) return NO;
        
        // FP=>D      ---->  <Empty>
        filePlayer.outputUnit = nil;
        if (![self connectTest: filePlayer: delay: outputUnit:0:nil: nil: nil]) return NO;
        
        // <Empty>    ---->  D=>Out
        delay.outputUnit = outputUnit;
        if (![self connectTest: filePlayer: delay: outputUnit:2: delay: outputUnit: nil]) return NO;
        
        // D=>Out     ---->  FP=>D=>Out
        filePlayer.outputUnit = delay;
        if (![self connectTest: filePlayer: delay: outputUnit:3: filePlayer: delay: outputUnit]) return NO;
        
        // FP=>D=>Out ---->  D=>Out
        filePlayer.outputUnit = nil;
        if (![self connectTest: filePlayer: delay: outputUnit:2: delay: outputUnit:nil]) return NO;
        
        // D=>Out     ---->  Empty
        delay.outputUnit = nil;
        if (![self connectTest: filePlayer: delay: outputUnit:0: nil: nil: nil]) return NO;
        
        // <Empty>    ---->  FP=>Out
        filePlayer.outputUnit = outputUnit;
        if (![self connectTest: filePlayer: delay: outputUnit:2:filePlayer: outputUnit: nil]) return NO;
        
        // FP=>Out    ---->  FP=>D
        filePlayer.outputUnit = delay;
        if (![self connectTest: filePlayer: delay: outputUnit:2:filePlayer: delay: nil]) return NO;
        
        // FP=>D      ---->  FP=>Out
        filePlayer.outputUnit = outputUnit;
        if (![self connectTest: filePlayer: delay: outputUnit:2:filePlayer: outputUnit: nil]) return NO;
        
        // FP=>Out    ---->  D=>Out
        delay.outputUnit = outputUnit;
        if (![self connectTest: filePlayer: delay: outputUnit:2:delay: outputUnit: nil]) return NO;
        
        // D=>Out     ---->  <Empty>
        delay.outputUnit = nil;
        if (![self connectTest: filePlayer: delay: outputUnit:0:nil: nil: nil]) return NO;
        
        // BUILD F=>D=>Out
        filePlayer.outputUnit = delay;
        delay.outputUnit = outputUnit;
        if (![self connectTest: filePlayer: delay: outputUnit:3:filePlayer: delay: outputUnit]) return NO;
        
        // FP=>D=>Out ----> FP=>Out
        filePlayer.outputUnit = outputUnit;
        if (![self connectTest: filePlayer: delay: outputUnit:2:filePlayer: outputUnit: nil]) return NO;
    }
    if (![CAudioUnit checkDeallocation:0]) return NO;
    return YES;
}


#define checkErrorAction(action,manager,err) expectAnError(manager,err,action)


// This checks
// (1) the graph is connected the way that is claimed.
// (2) the graph remains correct after any invalid or meaningless operation is done.


+ (BOOL) connectTest: (CAudioGenerator *) filePlayer
                    : (CAudioEffect *) delay
                    : (CAudioOutput *) outputUnit
                    : (NSUInteger) count
                    : (CAudioUnit *) u1
                    : (CAudioUnit *) u2
                    : (CAudioUnit *) u3
{
    CAudioUnit_currentError = nil;
    
    if (![self checkGraph:count:u1:u2:u3]) return NO;
    
    // Reset the output to it's current value; nothing happens
    if (!(CAudioUnitCheckError(0))) return NO;
    if (![self checkGraph:count:u1:u2:u3]) return NO;
    
    delay.outputUnit = delay.outputUnit;
    if (!(CAudioUnitCheckError(0))) return NO;
    if (![self checkGraph:count:u1:u2:u3]) return NO;
    
    filePlayer.outputUnit = filePlayer.outputUnit;
    if (!(CAudioUnitCheckError(0))) return NO;
    if (![self checkGraph:count:u1:u2:u3]) return NO;
    
    // Can't set somebody back to themselves.
    expectAnError(kAUGraphErr_InvalidConnection,
                  filePlayer.outputUnit = filePlayer;
                  );
    if (![self checkGraph:count:u1:u2:u3]) return NO;
    
    expectAnError(kAUGraphErr_InvalidConnection,
                  delay.outputUnit = delay;
                  )
    if (![self checkGraph:count:u1:u2:u3]) return NO;
    
    expectAnError(kAUGraphErr_InvalidConnection,
                  outputUnit.outputUnit = outputUnit;
                  )
    if (![self checkGraph:count:u1:u2:u3]) return NO;
    
    // Output unit can't take any output.
    expectAnError(kAUGraphErr_InvalidConnection,
                  outputUnit.outputUnit = filePlayer;
                  )
    if (![self checkGraph:count:u1:u2:u3]) return NO;
    
    expectAnError(kAUGraphErr_InvalidConnection,
                  outputUnit.outputUnit = delay;
                  )
    if (![self checkGraph:count:u1:u2:u3]) return NO;
    
    // File player can't receive anything.
    expectAnError((filePlayer.outputUnit == delay ? kAUGraphErr_InvalidConnection : kAudioUnitErr_InvalidElement),
                  delay.outputUnit = filePlayer;
                  );
    
    return YES;
}


// ---------------------------------------------------------------------------------------------------------------------
// Grid test 2: all possible units & connection failures
// ---------------------------------------------------------------------------------------------------------------------

+ (BOOL) unitGridTest
{
    @autoreleasepool {
        CAUGraph        * graph       = [CAUGraph new];
        CAudioOutput    * outputUnit  = [CAudioOutput defaultOutput:graph];
        CAudioGenerator * filePlayer  = [CAudioGenerator filePlayer:graph];
       
        filePlayer.outputUnit = outputUnit;
        
        // NSWindowController * fpwc = [self showWindowForUnit:filePlayer];
        
        NSArray * subTypes = [CAudioUnit subtypeNames:kCAudioUnitTypeName_Effect];
        
        printf("%s",[kCAudioUnitTypeName_Effect UTF8String]);
        
        for (NSString * subType in subTypes) {
            CAudioUnit * unit = [[CAudioEffect alloc] initWithSubtype:subType graph:graph];
            filePlayer.outputUnit = unit;
            unit.outputUnit = outputUnit;
            
            if (![CAudioUnit checkGraph: 3: filePlayer: unit :outputUnit]) {
                printf("Graph failed with effect: %s", unit.displayName.UTF8String);
                return NO;
            }
            
            //  [self runModalWindowForUnit:unit withTitle:[unit displayName]];
        }
        
        //     fpwc = nil;
        
    }
    if (![CAudioUnit checkDeallocation:0]) return NO;
    return YES;
}


// ---------------------------------------------------------------------------------------------------------------------
// UI Crash test
// ---------------------------------------------------------------------------------------------------------------------
// Doesn't work; probably because Cocoa needs to be in an application

+ (BOOL) UICrashTest
{
    @autoreleasepool {
        CAUGraph        * graph       = [CAUGraph new];
        CAudioGenerator * filePlayer  = [CAudioGenerator filePlayer:graph];
        
        // View controller with no output unit; should still work.
        NSViewController * vc = [filePlayer viewController];
        CASSERT_RET(vc != nil);
        CASSERT_RET([vc isKindOfClass:[NSViewController class]]);
        
        CAudioOutput    * outputUnit  = [CAudioOutput defaultOutput:graph];
        filePlayer.outputUnit = outputUnit;
        
        vc = [filePlayer viewController];
        CASSERT_RET(vc != nil);
        CASSERT_RET([vc isKindOfClass:[NSViewController class]]);

    }
    if (![CAudioUnit checkDeallocation:0]) return NO;
    
    return YES;
}




@end

#endif

