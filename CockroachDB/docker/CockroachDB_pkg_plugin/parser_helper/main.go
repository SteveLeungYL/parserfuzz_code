package main

import "C"
import (
	"encoding/json"
	"fmt"

	"github.com/cockroachdb/cockroach/pkg/sql/parser"
	_ "github.com/cockroachdb/cockroach/pkg/sql/sem/builtins"
	"github.com/cockroachdb/cockroach/pkg/sql/sem/tree"
)

//export ParseHelper
func ParseHelper(inData string) (*C.char, int) {

	// The return res from parser.Parse is an array of Statement structure.
	// Each element is one statement from the query.
	astTreeList, err, gramCov := parser.ParseWithCov(inData)
	if err != nil {
		return nil, 0
	}

	// Convert to SQLRight IR struct
	var irList []tree.SQLRightIR
	for _, curTree := range astTreeList {
		tmpIR := curTree.AST.LogCurrentNode(0)
		if tmpIR != nil {
			irList = append(irList, *tmpIR)
		} else {
			return nil, 0
		}
	}

	// Should convert to json string before passing back to C++ code.
	var jsonStrAllStatement string
	for idx, curIR := range irList {
		jsonStrAllStatement += fmt.Sprintf("idx: %d\n", idx)
		idx += 1
		jsonBytes, jErr := json.Marshal(curIR)
		if jErr != nil {
			return nil, 0
		}

		var m map[string]interface{}
		jErr = json.Unmarshal(jsonBytes, &m)
		if jErr != nil {
			return nil, 0
		}
		m["gramCov"] = gramCov
		jsonBytes, jErr = json.Marshal(m)

		jsonStr := string(jsonBytes)
		jsonStrAllStatement += jsonStr + "\n"
	}

	// Return the C char array version of jsonStrAllStatement.
	return C.CString(jsonStrAllStatement), len(jsonStrAllStatement)
}

func main() {
}
