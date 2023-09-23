#charset "us-ascii"
//
// sample.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// A non-interactive test of the memTest module.
//
// It can be compiled via the included makefile with
//
//	# t3make -f makefile.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

#include "memTest.h"

versionInfo: GameID;

gameMain: GameMainDef
	_table = nil

	newGame() {
		if(!memTest.referenceSave()) {
			"ERROR:  Failed to create reference save\n ";
			return;
		}

		memTest.report();

		doStuff();

		memTest.report();
	}

	// Just add something to the memory footprint.
	doStuff() {
		local i;

		_table = new LookupTable();
		for(i = 0; i < 10000; i++) {
			_table[i] = rand();
		}
	}
;
