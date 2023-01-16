// Copyright 2018 The Cockroach Authors.
//
// Use of this software is governed by the Business Source License
// included in the file licenses/BSL.txt.
//
// As of the Change Date specified in that file, in accordance with
// the Business Source License, use of this software will be governed
// by the Apache License, Version 2.0, included in the file
// licenses/APL.txt.

package rsg

import (
	"fmt"
	"os"
	"time"
	"testing"
	"strings"
)

func getRSG(t *testing.T, yaccExample []byte) *RSG {
	// The Random number generation seed is set to UnixNano. Always different.
	r, err := NewRSG(time.Now().UTC().UnixNano(), string(yaccExample), false)
	if err != nil {
		t.Fatal(err)
	}
	return r
}

func TestGenerate(t *testing.T) {
	tests := []struct {
		root        string
		depth       int
		repetitions int
	}{
		{
			root:        "select_stmt",
			depth:       2000, // Increase from default 20 to 2000.
			repetitions: 1000,
		},
	}

	yaccExample, err := os.ReadFile("./sql.y")
	if err != nil {
		t.Fatalf("error reading grammar: %v", err)
	}

	for _, tc := range tests {
		t.Run(fmt.Sprintf("%s-%d-%d", tc.root, tc.depth, tc.repetitions), func(t *testing.T) {

			if _, err := os.Stat("./generated_queries.log"); err == nil {
				os.Remove("./generated_queries.log")
                        }

			f, err := os.OpenFile("./generated_queries.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
			if err != nil {
				os.Exit(3);
			}
			defer f.Close();

			r := getRSG(t, yaccExample)

			out := make([]string, tc.repetitions)
			i := 0
			for i < tc.repetitions {
				s := r.Generate(tc.root, tc.depth)
				if strings.HasPrefix(s, "BEGIN") || strings.HasPrefix(s, "START") {
					continue;
					//return errors.New("transactions are unsupported")
				}
				if strings.HasPrefix(s, "SET SESSION CHARACTERISTICS AS TRANSACTION") {
					continue;
					//return errors.New("setting session characteristics is unsupported")
				}
				if strings.Contains(s, "READ ONLY") || strings.Contains(s, "read_only") {
					continue;
					//return errors.New("READ ONLY settings are unsupported")
				}
				if strings.Contains(s, "REVOKE") || strings.Contains(s, "GRANT") {
					continue;
					//return errors.New("REVOKE and GRANT are unsupported")
				}
				if strings.Contains(s, "EXPERIMENTAL SCRUB DATABASE SYSTEM") {
					continue;
					//return errors.New("See #43693")
				}
				out[i] = s
				fmt.Fprintf(f, "\nout[%d]: %v\n", i, s)
				i += 1
			}

		})
	}
}
