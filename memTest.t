#charset "us-ascii"
//
// memTest.t
//
//	A TADS3 module that provides a simple mechanism for doing 
//	before and after testing of savefile size.
//
// BASIC USAGE
//
//	Create a "reference" save file using:
//
//		// Return value is true on success, nil on failure
//		memTest.referenceSave();
//
//	Then at some later time you see the amount the savefile has grown
//	by using:
//
//		// Outputs a summary of the size difference
//		memTest.report();
//
//	You can "manually" create a test save (the "after" to the reference
//	save's "before") with:
//
//		// Create a savefile of the current state.
//		memTest.testSave();
//
//	And you can get the difference directly via:
//
//		// Returns difference, in bytes, between the test and
//		// reference save files.
//		memTest.getDifference();
//
//	By default both memTest.report() and memTest.getDifference() will
//	create a new test save when they're called (so they're reporting
//	the size difference as of the time when they're called).  If
//	you want to only create test saves via explicit calls to
//	memTest.testSave() you can call report() and getDifference() with
//	boolean true as the argument to prevent them from creating a
//	new test save.
//		
//
#include <adv3.h>
#include <en_us.h>

#include "memTest.h"

// Module ID for the library
memTestModuleID: ModuleID {
        name = 'Memory Test Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

memTest: PreinitObject
	// ID to use for output.
	id = 'memTest'

	// Filenames.
	fname0 = 'memTestBefore'	// name of reference save
	fname1 = 'memTestAfter'		// name of test save

	// Lookup table for caching file sizes.
	_sizes = perInstance(new LookupTable())

	// Saving will fail if there's no player or if the player's location
	// is nil, so we jump through some hoops to make sure we have both.
	_memTestPlayer = nil
	_memTestRoom = nil

	// Preinit logic to make sure we have a player and a room.
	execute() {
		local obj;

		// If there are no rooms defined, create one.
		if((obj = firstObj(Room)) == nil)
			obj = new Room();

		// Remember a room.  This can be either a "blank" one
		// we just created or a "real" one, it doesn't really
		// matter.
		_memTestRoom = obj;

		// Do the same thing we did above, only this time for
		// Person.
		if((obj = firstObj(Person)) == nil)
			obj = new Person();
		_memTestPlayer = obj;
	}

	// Returns the size of the named file.
	setFileSize(id) {
		local f;

		// Open the file for reading.
		try { f = File.openDataFile(id, FileAccessRead); }
		catch(Exception e) { return(nil); }

		// Remember the file size.
		_sizes[id] = f.getFileSize();
		f.closeFile();

		// Return the file size.
		return(_sizes[id]);
	}

	// Returns a previously-computed file size.
	getFileSize(id) { return(_sizes[id]); }

	// Save the game without prompting the player.
	noninteractiveSave(id) {
		debug('Saving to file <q><<id>></q>.');
		return(MemTestSaveAction.performFileOp(id, true));
	}

	// Handle everything related to saving the game (noninteractively)
	// and remembering the file size.
	_saveFile(id) {
		local p0, p1;

		// Make sure we have a player.
		if(gPlayerChar == nil) {
			setPlayer(_memTestPlayer);
			p0 = true;
		}

		// Make sure the player has a location.
		if(gPlayerChar.location == nil) {
			gPlayerChar.location = _memTestRoom;
			p1 = true;
		}

		// Do the hands-off save.
		if(!noninteractiveSave(id))
			return(nil);

		// Remember the file size.
		if(!setFileSize(id))
			return(nil);

		// Campground rules:  return everything to the state
		// before we got here.
		if(p1 == true)
			gPlayerChar.location = nil;
		if(p0 == true)
			setPlayer(nil);

		return(true);
	}

	// Create a "reference" save.  The "before" snapshot we'll
	// compare against.
	referenceSave() { return(_saveFile(fname0)); }

	// Create a "test" save.  This is the "after" snapshot.
	testSave() { return(_saveFile(fname1)); }

	// Compare the "before" and "after" snapshots.
	// Arg is a boolean flag.  If true, we'll never create a
	// test snapshot if one doesn't exist.
	getDifference(checkOnly?) {
		local sz0, sz1;

		// Get the reference file size.  If it's nil, that
		// means we don't have a reference snapshot.  Bail.
		if((sz0 = getFileSize(fname0)) == nil)
			return(nil);

		if(checkOnly == true) {
			// If the checkOnly flag is set, only continue if
			// there's an existing test save.
			sz1 = getFileSize(fname1);
		} else {
			// Otherwise we create a test save and get its
			// size.
			if(!testSave())
				return(nil);
			sz1 = getFileSize(fname1);
		}

		// Make sure we got a test size above.
		if(sz1 == nil)
			return(nil);
		
		// The difference of the two save file sizes.  We
		// assume the (earlier) "reference" file will be
		// smaller than the (later) "test" file.
		return(sz1 - sz0);
	}

	// Convenience method for outputting a message with the logging ID.
	log(msg) { aioSay('\n<<id>>: <<msg>>\n '); }

	// Stub.  Overwritten if compiled with -D __DEBUG_MEM_TEST
	debug(msg) {}

	// Reporting method.
	// Outputs a summary of the file size differences.
	report(checkOnly?) {
		local d;

		if((d = getDifference(checkOnly)) == nil) {
			log('failed to compute difference');
			return(nil);
		}
		log('Savefile <<(d >= 0) ? 'grew' : 'shrank'>>
			by <<((d >0) ? toString(d) : -d)>> bytes.');
		return(true);
	}
;

// Slight modification of SaveAction.
// It SHOULD be logically identical except a)  this version doesn't
// output anything but it does b)  give a return value indicating
// success or failure.
DefineAction(MemTestSave, SaveAction)
	showCancelMsg() {}
	performFileOp(fname, ack, desc:?) {
		PreSaveObject.classExec();
		try { saveGame(fname, gameMain.getSaveDesc(desc)); }
		catch(Exception e) { return(nil); }
		return(true);
	}
;
