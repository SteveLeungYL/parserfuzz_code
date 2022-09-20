package main

import "C"
import (
	"github.com/cockroachdb/cockroach/pkg/sql/parser"
	_ "github.com/cockroachdb/cockroach/pkg/sql/sem/builtins"
)

//export ParseHelper
func ParseHelper(inData string) string {
	_, err := parser.Parse(string(inData))

	// The return res is an array of Statement structure.
	// Should convert to json string before passing back to C++ code.

	if err != nil {
		return ""
	}
	return "Succeed"
}

func main() {}
