package edgeClassifier

import "strings"

func IsMySQLCompNode(_ string, nodeValue string) bool {

	if strings.Contains(nodeValue, "expr") || strings.Contains(nodeValue, "subquery") ||
		strings.Contains(nodeValue, "joined_table") || strings.Contains(nodeValue, "list") {
		return true
	}
	switch nodeValue {
	case "subquery":
		fallthrough
	case "expr":
		return true
	}
	return false
}

func IsMySQLSquirrelCompNode(_ string, nodeValue string) bool {

	if strings.Contains(nodeValue, "expr") || strings.Contains(nodeValue, "select_no_parens") ||
		strings.Contains(nodeValue, "select_with_parens") ||
		strings.Contains(nodeValue, "operand") {
		return true
	}
	return false
}
