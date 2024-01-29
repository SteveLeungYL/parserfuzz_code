package edgeClassifier

import (
	"github.com/rsg/yacc"
	"strings"
)

func IsCockroachDBCompNode(_ string, nodeValue string) bool {

	if strings.Contains(nodeValue, "expr") ||
		strings.Contains(nodeValue, "select_") ||
		strings.Contains(nodeValue, "table_ref") {
		return true
	}
	return false
}

func RemoveCockroachDBUnimplementedRule(inputProds map[string][]*yacc.ExpressionNode) {
	// map in GoLang is passed by reference. Any changes inside the function will affect the original values.
	var trimmedInputProds map[string][]*yacc.ExpressionNode = make(map[string][]*yacc.ExpressionNode)
	for rootStr, rules := range inputProds {
		var trimmedRules []*yacc.ExpressionNode
		for _, curRule := range rules {
			isErrorRule := false
			for _, curTerm := range curRule.Items {
				if curTerm.Value == "error" ||
					strings.Contains(curTerm.Value, "keyword") {
					isErrorRule = true
					break
				}
			}
			if !isErrorRule {
				trimmedRules = append(trimmedRules, curRule)
			}
		}
		trimmedInputProds[rootStr] = trimmedRules
	}

	for rootStr, trimmedRules := range trimmedInputProds {
		inputProds[rootStr] = trimmedRules
	}

	return
}
