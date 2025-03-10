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
	. "github.com/rsg/constant_structs"
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

func getRSG(yaccExample []byte, dbmsName string, epsilon float64, fuzzingMode FuzzingMode) *RSG {
	// The Random number generation seed is set to UnixNano. Always different.
	r, err := NewRSG(time.Now().UTC().UnixNano(), string(yaccExample), dbmsName, epsilon, fuzzingMode)
	if err != nil {
		os.Exit(1)
	}
	return r
}

func generateNormal(tc TestCase, dbmsName string) string {
	return r.Generate(tc.root, dbmsName, tc.depth)
}

func generatePostgresSelect() string {
	targets := r.Generate("target_list", "cockroachdb", 30)
	where := r.Generate("where_clause", "cockroachdb", 30)
	from := r.Generate("from_clause", "cockroachdb", 30)

	s := fmt.Sprintf("SELECT %s %s %s", targets, from, where)
	return s
}

func generateCockroachDBSelect() string {
	//targets := r.Generate("target_list", "cockroachdb", 30)
	//where := r.Generate("where_clause", "cockroachdb", 30)
	//from := r.Generate("from_clause", "cockroachdb", 30)
	//
	//s := fmt.Sprintf("SELECT %s %s %s", targets, from, where)
	s := r.Generate("select_stmt", "cockroachdb", 2)
	return s
}

//export RSGInitialize
func RSGInitialize(fileName string, dbmsName string, epsilon float64, fuzzingModeStr string) {

	yaccExample, err := os.ReadFile(fileName)
	if err != nil {
		fmt.Printf("error reading grammar: %v\n", err)
		os.Exit(1)
	}

	fuzzingMode := r.identifyFuzzingMode(fuzzingModeStr)

	fmt.Printf("Initialize ParserFuzz RSG module with fuzzing mode: %s and epsilon %f\n", fuzzingModeStr, epsilon)

	r = getRSG(yaccExample, dbmsName, epsilon, fuzzingMode)

	return

}

//export RSGClearChosenExpr
func RSGClearChosenExpr() {
	r.ClearChosenExpr()
	return
}

//export RSGDumpParserRuleMap
func RSGDumpParserRuleMap(outFile string) {
	r.DumpParserRuleMap(outFile)
	return
}

//export RSGExecSucceed
func RSGExecSucceed() {

	r.IncrementSucceed()
	return

}

//export RSGSaveFav
func RSGSaveFav() {

	r.SaveFav()
	return

}

//export RSGExecFailed
func RSGExecFailed() {

	r.IncrementFailed()
	return

}

//export RSGQueryGenerate
func RSGQueryGenerate(genType string, dbmsName string) (*C.char, int) {
	tc := TestCase{
		root:        genType,
		depth:       2, // Increase from default 20 to 30.
		repetitions: 1,
	}

	if dbmsName == "sqlite" {
		tc.depth = 1
	} else if dbmsName == "sqlite_bison" {
		tc.depth = 12
	} else if dbmsName == "cockroachdb" {
		tc.depth = 1
	} else if dbmsName == "tidb" {
		tc.depth = 1
	} else if dbmsName == "duckdb" {
		tc.depth = 1
	}

	var s = ""
	if strings.Contains(tc.root, "select_stmt") && dbmsName == "cockroachdb" {
		s = generateCockroachDBSelect()
	} else if strings.Contains(tc.root, "select_stmt") && dbmsName == "postgres" {
		s = generatePostgresSelect()
	} else {
		s = generateNormal(tc, dbmsName)
	}

	if dbmsName == "cockroachdb" {
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
	}

	return C.CString(s), len(s)
}

func main() {
	RSGInitialize("./parser_def_files/duckdb_grammar.y", "duckdb", 0.3, "normal")
	for idx := 0; idx < 100; idx++ {
		RSGQueryGenerate("select_no_parens", "duckdb")
		RSGQueryGenerate("select_no_parens", "duckdb")
		RSGQueryGenerate("select_no_parens", "duckdb")
		RSGExecSucceed()
	}
}
