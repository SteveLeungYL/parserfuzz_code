package rsgGenerator

import (
	"fmt"
	"github.com/rsg/yacc"
	"strings"
	"unicode"
)

func GenerateDuckDB(r RSGInterface, root string, rootPathNode *PathNode, parentHash uint32, depth int, rootDepth int) []string {

	//fmt.Printf("\n\n\nLooking for root: %s, depth :%d\n\n\n", root, depth)
	replayingMode := false
	isChooseCompRule := false
	isFavPathNode := false

	if rootPathNode == nil {
		fmt.Printf("\n\n\nError: rootPathNode is nil. \n\n\n")
		// Return nil is different from return an empty array.
		// Return nil represent error.
		return nil
	}

	if len(r.GetAllProds()[root]) == 0 {
		fmt.Printf("Error: Getting empty r.allProds[root], root is: %s\n", root)
		ret := make([]string, 0)
		ret = append(ret, root)
		return ret
	}

	// Initialize to an empty slice instead of nil because nil means error.
	ret := make([]string, 0)

	//fmt.Printf("\n\n\n From root: %s, getting allProds size: %d, depth: %d \n\n\n", root, len(r.allProds[root]), depth)
	var curChosenRule *yacc.ExpressionNode
	if rootPathNode.ExprProds == nil {
		// Not in the replaying mode, choose one node using MABChooseARM and proceed.
		replayingMode = false

		curRuleSet := r.PrioritizeParserRules(root, parentHash, depth)

		curChosenRule = r.MABChooseArm(curRuleSet)

		// Mark the current parent to child rule as triggered.
		r.MarkEdgeCov(parentHash, curChosenRule.UniqueHash)

		// Check whether all rules in the current root keyword is triggered.
		// If not all are triggered, set is isFav = true
		isFavPathNode = r.CheckIsFav(root, parentHash)

		// Check whether the chosen rule is complex rule, i.e., select, expr, nexpr etc.
		isChooseCompRule = r.IsInCompProds(root, curChosenRule)

		rootPathNode.ExprProds = curChosenRule
		rootPathNode.Children = []*PathNode{}
	} else {
		// Replay mode, directly reuse the previous chosen rule.
		replayingMode = true
		curChosenRule = rootPathNode.ExprProds
	}

	if curChosenRule == nil {
		fmt.Printf("\n\n\nERROR: getting nil curChosenRule. \n\n\n")
		return nil
	}

	rootHash := curChosenRule.UniqueHash

	replayExprIdx := 0

	for _, item := range curChosenRule.Items {
		switch item.Typ {
		case yacc.TypLiteral:
			v := item.Value[1 : len(item.Value)-1]
			ret = append(ret, v)
			continue
		case yacc.TypToken:

			var v []string
			tokenStr := item.Value

			if depth <= 0 {
				if tokenStr == "SelectStmt" || tokenStr == "select_no_parens" || tokenStr == "simple_select" {
					ret = append(ret, " SELECT 'abc' ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				} else if tokenStr == "a_expr" || tokenStr == "b_expr" || tokenStr == "c_expr" || tokenStr == "d_expr" {
					ret = append(ret, " True ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				} else if tokenStr == "select_clause" || tokenStr == "select_with_parens" {
					ret = append(ret, " ( SELECT TRUE ) ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				} else if tokenStr == "returning_clause" {
					ret = append(ret, " ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				} else if tokenStr == "table_ref" {
					ret = append(ret, " v0 ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				} else if tokenStr == "joined_table" {
					ret = append(ret, " v0 ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				} else if tokenStr == "PreparableStmt" {
					ret = append(ret, " SELECT 'abc' ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				}
			}

			switch tokenStr {
			case "IDENT":
				v = []string{"v0"}
			case "SCONST":
				v = []string{`'string'`}
			case "ICONST":
				v = []string{`100`}
			case "FCONST":
				v = []string{`100.0`}
			case "BCONST":
				v = []string{`'101010'::BIT`}
			case "XCONST":
				v = []string{`'101010'::BIT`}
			case "TYPECAST":
				v = []string{"::"}
			case "COLON_EQUALS":
				v = []string{":="}
			case "LAMBDA_ARROW":
				v = []string{"->"}
			case "DOUBLE_ARROW":
				v = []string{"->>"}
			case "POWER_OF":
				v = []string{"**"}
			case "INTEGER_DIVISION":
				v = []string{"//"}
			case "EQUALS_GREATER":
				v = []string{"=>"}
			case "LESS_EQUALS":
				v = []string{"<="}
			case "GREATER_EQUALS":
				v = []string{">="}
			case "LESS_GREATER":
				v = []string{"<>"}
			case "NOT_EQUALS":
				v = []string{"!="}
			case "Op":
				v = []string{"~"}

			default:

				isUpperCase := true
				// The only way to get a rune from the string seems to be retrieved from for
				curValue := strings.ReplaceAll(item.Value, "_P", "")
				curValue = strings.ReplaceAll(curValue, "_LA", "")
				for _, c := range curValue {
					isUpperCase = unicode.IsUpper(c) || c == '_'
					if isUpperCase == false {
						break
					}
				}

				if isUpperCase {
					ret = append(ret, curValue)
					continue
				}

				var newChildPathNode *PathNode
				if !replayingMode {
					newChildPathNode = &PathNode{
						Id:        r.GetPathId(),
						Parent:    rootPathNode,
						ExprProds: nil,
						Children:  []*PathNode{},
						IsFav:     isFavPathNode,
						// Debug
						//ParentStr: root,
					}
					r.SetPathId(r.GetPathId() + 1)
					rootPathNode.Children = append(rootPathNode.Children, newChildPathNode)
					if isChooseCompRule {
						// Choosing the complex rules, depth - 1.
						v = GenerateDuckDB(r, item.Value, newChildPathNode, rootHash, depth-1, rootDepth)
					} else {
						// If not choosing the complex rules, depth not decrease.
						v = GenerateDuckDB(r, item.Value, newChildPathNode, rootHash, depth, rootDepth)
					}
				} else {
					if replayExprIdx >= len(rootPathNode.Children) {
						fmt.Printf("\n\n\nERROR: The replaying node is not consistent with the saved structure. \n"+
							"root: %s, idx: %d, children size: %d"+
							"\n\n\n", root, replayExprIdx, len(rootPathNode.Children))
						return nil
					}
					newChildPathNode = rootPathNode.Children[replayExprIdx]
					replayExprIdx += 1
					//fmt.Print("(debug) using replaying mode. \n\n\n")
					// We won't decrease depth number in replaying mode.
					v = GenerateDuckDB(r, item.Value, newChildPathNode, rootHash, depth, rootDepth)
				}

			}
			if v == nil {
				fmt.Printf("\n\n\nError: v == nil in the RSGInterface. Root: %s, item: %s\n\n\n", root, item.Value)
				return nil
			}
			ret = append(ret, v...)
		default:
			panic("unknown item type")
		}
	}
	return ret
}
