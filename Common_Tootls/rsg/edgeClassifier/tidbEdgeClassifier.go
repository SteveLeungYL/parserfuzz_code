package edgeClassifier

import (
	"github.com/rsg/yacc"
	"strings"
)

func IsTiDBCompNode(_ string, nodeValue string) bool {

	if nodeValue == "SubSelect" || nodeValue == "Expression" || nodeValue == "JoinTable" {
		return true
	}
	if strings.Contains(nodeValue, "expr") || strings.Contains(nodeValue, "Expr") || strings.Contains(nodeValue, "List") || strings.Contains(nodeValue, "list") {
		return true
	}
	return false
}

func RemoveTiDBUnimplementedRule(inputProds map[string][]*yacc.ExpressionNode) {
	// map in GoLang is passed by reference. Any changes inside the function will affect the original values.
	var trimmedInputProds map[string][]*yacc.ExpressionNode = make(map[string][]*yacc.ExpressionNode)
	for rootStr, rules := range inputProds {
		var trimmedRules []*yacc.ExpressionNode
		for _, curRule := range rules {
			isErrorRule := false
			for _, curTerm := range curRule.Items {
				if strings.Contains(curTerm.Value, "invalid") {
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
