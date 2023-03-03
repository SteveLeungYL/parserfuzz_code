// Copyright 2018 The Cockroach Authors.
//
// Use of this software is governed by the Business Source License
// included in the file licenses/BSL.txt.
//
// As of the Change Date specified in that file, in accordance with
// the Business Source License, use of this software will be governed
// by the Apache License, Version 2.0, included in the file
// licenses/APL.txt.

package main

import "C"
import (
	"fmt"
	"os"
	"strings"
	"time"
)

var r *RSG

type TestCase struct {
	root        string
	depth       int
	repetitions int
}

func getRSG(yaccExample []byte, dbmsName string) *RSG {
	// The Random number generation seed is set to UnixNano. Always different.
	r, err := NewRSG(time.Now().UTC().UnixNano(), string(yaccExample), dbmsName, false)
	if err != nil {
		os.Exit(1)
	}
	return r
}

func generateNormal(tc TestCase, dbmsName string) string {
	return r.Generate(tc.root, dbmsName, tc.depth)
}

func generateCockroachDBSelect() string {
	targets := r.Generate("target_list", "cockroachdb", 30)
	where := r.Generate("where_clause", "cockroachdb", 30)
	from := r.Generate("from_clause", "cockroachdb", 30)

	s := fmt.Sprintf("SELECT %s %s %s", targets, from, where)
	return s
}

//export RSGInitialize
func RSGInitialize(dbmsName string) {

	yaccExample, err := os.ReadFile("./sql.y")
	if err != nil {
		fmt.Printf("error reading grammar: %v", err)
		os.Exit(1)
	}

	r = getRSG(yaccExample, dbmsName)

	return

}

//export RSGQueryGenerate
func RSGQueryGenerate(genType string, dbmsName string) (*C.char, int) {
	tc := TestCase{
		root:        genType,
		depth:       30, // Increase from default 20 to 30.
		repetitions: 1,
	}

	var s = ""
	if strings.Contains(tc.root, "select_stmt") && dbmsName == "cockroachdb" {
		s = generateCockroachDBSelect()
	} else {
		s = generateNormal(tc, dbmsName)
	}

	if strings.HasPrefix(s, "BEGIN") || strings.HasPrefix(s, "START") {
		//fmt.Printf("\n\n\nDEBUG: Getting BEGIN or START\n\n\n")
		return nil, 0
	}
	if strings.HasPrefix(s, "SET SESSION CHARACTERISTICS AS TRANSACTION") {
		//fmt.Printf("\n\n\nDEBUG: Getting SET SESSION CHARACTERISTICS AS TRANSACTION\n\n\n")
		return nil, 0
	}
	if strings.Contains(s, "READ ONLY") {
		strings.Replace(s, "READ ONLY", "READ WRITE", -1)
	}
	if strings.Contains(s, "read_only") {
		//fmt.Printf("\n\n\nDEBUG: Getting read_only\n\n\n")
		return nil, 0
	}
	if strings.Contains(s, "REVOKE") || strings.Contains(s, "GRANT") {
		//fmt.Printf("\n\n\nDEBUG: Getting REVOKE or GRANT\n\n\n")
		//fmt.Printf("\n\n\n%s\n\n\n", s)
		return nil, 0
	}
	if strings.Contains(s, "EXPERIMENTAL SCRUB DATABASE SYSTEM") {
		//fmt.Printf("\n\n\nDEBUG: Getting EXPERIMENTAL SCRUB\n\n\n")
		return nil, 0
	}

	return C.CString(s), len(s)
}

func main() {}
