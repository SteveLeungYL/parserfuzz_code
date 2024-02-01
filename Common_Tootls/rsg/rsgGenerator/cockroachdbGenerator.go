package rsgGenerator

import (
	"fmt"
	. "github.com/rsg/constant_structs"
	"github.com/rsg/yacc"
	"strings"
	"unicode"
)

func GenerateCockroach(r RSGInterface, root string, rootPathNode *PathNode, parentHash uint32, depth int, rootDepth int) []string {

	if depth <= 0 && r.GetCurFuzzingMode() >= FuzzingModeNoFavNoMABNoAccNoCat {
		// If the depth is deep. AND the fuzzing mode is not helping.
		// Forced terminating the generation process to prevent crashing.
		return make([]string, 0)
	}

	//fmt.Printf("\n\n\nLooking for root: %s\n\n\n", root)
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
		// It is indeed possible to have 0 length rules for the CockroachDB parser.
		// For example:
		/* alter_unsupported_stmt:
		  ALTER DOMAIN error
		  {
		    return unimplemented(sqllex, "alter domain")
		  }
		| ALTER AGGREGATE error
		  {
		    return unimplementedWithIssueDetail(sqllex, 74775, "alter aggregate")
		  }
		*/
		return make([]string, 0)
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

			if strings.Contains(tokenStr, "_LA") {
				tokenStr = strings.ReplaceAll(tokenStr, "_LA", "")
			}
			if strings.Contains(tokenStr, "NOTHING_AFTER_RETURNING") {
				tokenStr = "NOTHING"
			}
			if strings.Contains(tokenStr, "'IDENT'") {
				tokenStr = "IDENT"
			}
			if strings.Contains(tokenStr, "INDEX_BEFORE_PAREN") || strings.Contains(tokenStr, "INDEX_BEFORE_NAME_THEN_PAREN") ||
				strings.Contains(tokenStr, "INDEX_AFTER_ORDER_BY_BEFORE_AT") {
				tokenStr = "INDEX"
			}

			if depth < 0 {
				if tokenStr == "simple_select" || tokenStr == "select_no_parens" {
					ret = append(ret, " SELECT 'abc' ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				} else if tokenStr == "c_expr" || tokenStr == "a_expr" || tokenStr == "b_expr" {
					tokenStr = "d_expr"
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
				} else if tokenStr == "d_expr" {
					ret = append(ret, "'string'")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				} else if tokenStr == "table_ref" {
					ret = append(ret, " v0 ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				}
			}

			switch tokenStr {
			case "IDENT":
				v = []string{"ident"}

			case "SCONST":
				v = []string{`'string'`}
			case "ICONST":
				v = []string{fmt.Sprint(r.Intn(1000) - 500)}
			case "FCONST":
				v = []string{fmt.Sprint(r.Float64())}
			case "BCONST":
				v = []string{`b'bytes'`}
			case "BITCONST":
				v = []string{`B'10010'`}
			case "substr_from":
				v = []string{"FROM", `'string'`}
			case "substr_for":
				v = []string{"FOR", `'string'`}
			case "overlay_placing":
				v = []string{"PLACING", `'string'`}
			case "error":
				v = []string{}
			default:

				isFirstUpperCase := false
				// The only way to get a rune from the string seems to be retrieved from for
				for _, c := range item.Value {
					isFirstUpperCase = unicode.IsUpper(c)
					break
				}

				if isFirstUpperCase {
					ret = append(ret, item.Value)
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
						v = GenerateCockroach(r, item.Value, newChildPathNode, rootHash, depth-1, rootDepth)
					} else {
						// If not choosing the complex rules, depth not decrease.
						v = GenerateCockroach(r, item.Value, newChildPathNode, rootHash, depth, rootDepth)
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
					// We won't decrease depth number in replaying mode.
					v = GenerateCockroach(r, item.Value, newChildPathNode, rootHash, depth, rootDepth)
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
