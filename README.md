# CAudioUnits
This is a simple and robust interface for managing AudioUnits, with UI, NSEncoding and NSError support, and where all CAudioUnits are completely non-modal.

##Usage

####Basic construction: CAudioUnit.h
Audio units are ready to go as soon as they are initialized. They are constructed using "subtype name".  All you have to do is connect them, e.g.<pre>
        auSynthesizer = [[CAudioInstrument alloc] initWithSubtype:@"Apple: DLSMusicDevice"];
        auEffect      = [[CAudioEffect alloc] initWithSubtype:@"Apple: AUPitch"];
        auOutput      = [[CAudioOutput alloc] initWithSubtype:@"Apple: DefaultOutputUnit"];</pre>
        
To get a list of available subtypes (to load into a menu, for example). (You can also use this check the correct spelling of the string.)<pre>
        NSArray * subTypes = [CAudioOutput subtypeNames];</pre>

To create a signal processing graph, just connect them using the outputUnit property:<pre>
      auSynthesizer.outputUnit = auEffect;
      auEffect.outputUnit = auOutput;</pre>

The graph is now rendering audio. Sending MIDI to the synthesizer will produce output at the speakers. (Every graph must contain an output unit to send audio to the speakers.)

####User interface: CAudioUnit+UI.h.
Almost all audio units have a built in user interface. To load this into a window, use the viewController property.<pre>
      synthViewC = auSynthesizer.viewController;</pre>
Add the view to a window:<pre>
      [window setContentViewController:synthViewC]</pre>
Add the view to an NSBox:<pre>
      [nsBox setContentView:synthViewC.view];</pre>
You may need to retain a pointer to the view controller to keep ARC from deallocating it. 
    

##Design goals

####Simplicity

This interface is designed to allow clients to do simple things quickly, safely and easily, while knowing almost nothing about audio units and what else they can do. It provides almost no features whatsoever; if a client needs more features, they should call Apple's AudioUnit and AUGraph routines directly. 

####Non-modality

An object is "non-modal" if it remains fully functional and operating from the initialization to deallocation. With ARC, this means that if you have a valid pointer to the object then you are pointing to a fully functional object.
No other initialization or clean up is needed.

A non-modal object does not have an "error mode". If an error occurs, the object and its relationships remain unchanged. Thus the caller *always* has a working AudioUnit signal chain, which is still processing audio. If CAUError_currentError != nil, then there has been an error since the last time you checked, but the audio units are still running and valid.

Apple's AUGraph, in particular, is incredibly modal: open/closed; initialized/uninitialized; pending changes/updated; running/not running/can't run. There are many possible error states, and these are difficult to unwind. This interface elimnates these problems. It's dumb-proof.

Failure to initialize returns nil and no change is made to the system. (E.g., if the user asks for a type of unit that is no longer available, etc.)

Connections between units are either possible or impossible. If the client assigns the output of CAudioUnit in a way that doesn't make sense, no connections in the graph are changed. If the client makes a connection on a bus that is already in use, the old connection is broken before the new connection is made. In other words, making a connection operates like "assign"; the previous assignment is forgotten. If two units can't be connected, "setOutputUnit" does nothing and an NSError object is created at CAUError and can be retrieved from there.

####Thread safety

Setting the output unit(s) (or any other property in the future) is thread safe and does not require an interruption in the data flow.

##Todo
####Features not supported
- Properties and parameters.  I need a category that handles the general case (i.e. properties and parameters as "NSValues"); we will need this core functionality for third party audio units. For known classes,  we can create client-friendly objective-C methods and @properties of the object. With the core functionality, this last step is just busy work, and it gives us KVC control of the parameters. We PROBABLY need this for my project.

- MIDI control of parameters. I understand that (at least some AUs) can be controlled through MIDI messages. This entails that every audio unit should be a MIDI receiver. We need a category on AudioUnit that handles this. We MAY need this for my project.

-  Busses other than 0 -- we currently only support a straight, one dimensional signal chains. This is not needed for the current project.

- This interface currently only supports MusicDevices, Generators, Effects and Outputs. Without busses, we can't support mixers or panners. The remaining types are sufficiently different that I'm not sure if this interface would be useful at all.

- Sub-graphs. Completely beyond the scope of my project.

####Possible Issues
- If a caller creates a second output unit in the same graph, the error is not reported, and the first one will act unpredictably.
- NSCoding: CAudioUnits are saved, not the CAUGraph. A CAudioUnit will save all units that it is connected to.

####Minor bugs to be fixed with help
These remaining bugs are beyond my expertise and the scope of the current project.
- Error handling is not done correctly -- this is not my area of expertise. It needs to report the errors with NSLocalized strings, etc. There could also be much more detail in how the errors are reported. 
- The search function does not find all the instruments loaded on this computer. Superior Drummer does not appear. This is beyond my expertise -- I think I need to search the file system myself.
- AU Cocoa views have occasional bugs, but I think this has more to do with the Cocoa views than with my code.
- Vienna Instrument View no longer loads. Used to work. Don't know what changed. CHECK THIS; MAY BE FIXED.
- This only tries to get the first Cocoa view. If there are other views available, this will never see it.
- Will not produce a second Cocoa view for a unit -- at least, it won't for an AUAudioFilePlayer.
- AUDelay's view doesn't look right when we first load it, but resizing the window fixes it immediately. I've seen this problem before, but I'm not sure what the fix is. Outside the scope of my current project.
- There is also something wrong with AUFilePlayer's view -- it prints a bunch of complaints to stdout when it opens. It's using outdated methods for something, and the constraints aren't worked out right somehow Also outside the scope of my current project.
- AUFilePlayer doesn't like it when you change the output -- which makes this makes the demo look really bad. See the "MIDIFilePlayerWithEffect" demo, which shows that the DLSMusicDevice is perfectly happy with changing effects on the fly. The fix would be to try to make CAudioFilePlayer more "non-modal": when we set the output, we need to stop playback, at least, and restart it if that's what takes. This would part of a general implementation of CAudioFilePlayer as fully realized object, with all the properties, parameters, and actions that are available implemented as client-friendly objective-C properties and methods. Outside the scope of my current project.
- I was not able to get AUGraphUpdate to handle error recovery in a way that worked at all. The graph does not seem to properly queue the changes, and queries of the graph return information about the current state, ignoring the queue. Once an error occurs, it does a terrible job of unwinding the error. So now I stop the graph before making changes. This defeats the whole purpose and will probably cause some kind of audible glitch at some point.
- Couldn't figure out how objective-C is changing pointers during dealloc process. See Kludge (1) in CAudioUnit.m.




