package main
import "C"
import (
    "github.com/cockroachdb/cockroach/pkg/sql/parser"
    "os"
    _ "github.com/cockroachdb/cockroach/pkg/sql/sem/builtins"
)

//export ParseHelper
func ParseHelper(inData string) {
    _, err := parser.Parse(string(inData))
    if err != nil {
        return
    }
    return
}

func main() {
    data, inputErr := os.ReadFile("./input_query.sql")
    if inputErr != nil {
        return
    }
    ParseHelper(string(data))
    return
}
