package edgeClassifier

import (
	"github.com/rsg/yacc"
	"strings"
)

func IsDuckDBCompNode(_ string, nodeValue string) bool {

	if nodeValue == "SelectStmt" || nodeValue == "expr" || nodeValue == "joined_table:" ||
		nodeValue == "PreparableStmt" || nodeValue == "table_ref" {
		return true
	}
	if strings.Contains(nodeValue, "select") || strings.Contains(nodeValue, "expr") ||
		strings.Contains(nodeValue, "_list") ||
		strings.Contains(nodeValue, "opt_") ||
		strings.Contains(nodeValue, "table_ref") {
		return true
	}
	return false
}

func RemoveDuckDBKeywordPlaceholder(inputProds map[string][]*yacc.ExpressionNode) {
	// map in GoLang is passed by reference. Any changes inside the function will affect the original values.
	var trimmedInputProds = make(map[string][]*yacc.ExpressionNode)
	for rootStr, rules := range inputProds {
		var trimmedRules []*yacc.ExpressionNode
		for _, curRule := range rules {
			isErrorRule := false
			for _, curTerm := range curRule.Items {
				if strings.Contains(curTerm.Value, "unreserved_keyword") ||
					strings.Contains(curTerm.Value, "col_name_keyword") ||
					strings.Contains(curTerm.Value, "func_name_keyword") ||
					strings.Contains(curTerm.Value, "type_name_keyword") ||
					strings.Contains(curTerm.Value, "other_keyword") ||
					strings.Contains(curTerm.Value, "type_func_name_keyword") ||
					strings.Contains(curTerm.Value, "reserved_keyword") {
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

func FindTuningDuckDBRules(inputProds map[string][]*yacc.ExpressionNode) {
	// map in GoLang is passed by reference. Any changes inside the function will affect the original values.
	var trimmedInputProds = make(map[string][]*yacc.ExpressionNode)
	for rootStr, rules := range inputProds {
		var trimmedRules []*yacc.ExpressionNode

		for _, curRule := range rules {
			isRemove := false

			// Case of ColIdOrStr. Remove the SCONST case. Always use Identifier.
			if rootStr == "ColIdOrString" {
				for _, curTerm := range curRule.Items {
					if strings.Contains(curTerm.Value, "SCONST") {
						isRemove = true
						break
					}
				}
			}

			// Case of key_match, not implemented
			if rootStr == "key_match" {
				for _, curTerm := range curRule.Items {
					if strings.Contains(curTerm.Value, "PARTIAL") {
						isRemove = true
						break
					}
				}
			}

			// Avoid using indirection
			for _, curTerm := range curRule.Items {
				if strings.Contains(curTerm.Value, "indirection") && !strings.Contains(curTerm.Value, "opt_indirection") {
					isRemove = true
					break
				}
			}

			if !isRemove {
				trimmedRules = append(trimmedRules, curRule)
			}
		}

		// End of the modifications
		trimmedInputProds[rootStr] = trimmedRules
	}

	for rootStr, trimmedRules := range trimmedInputProds {
		inputProds[rootStr] = trimmedRules
	}

	return
}
