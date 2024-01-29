package rsgGenerator

import (
	"fmt"
	"github.com/rsg/yacc"
)

func GenerateMySQLSquirrel(r RSGInterface, root string, rootPathNode *PathNode, parentHash uint32, depth int, rootDepth int) []string {

	//fmt.Printf("\n\n\nLooking for root: %s, depth: %d\n\n\n", root, depth)
	replayingMode := false
	isChooseCompRule := false
	isFavPathNode := false

	if rootPathNode == nil {
		fmt.Printf("\n\n\nError: rootPathNode is nil. \n\n\n")
		// Return nil is different from return an empty array.
		// Return nil represent error.
		return nil
	}

	// Initialize to an empty slice instead of nil because nil means error.
	ret := make([]string, 0)

	//fmt.Printf("\n\n\n From root: %s, getting allProds size: %d \n\n\n", root, len(allProds))
	var curChosenRule *yacc.ExpressionNode
	if rootPathNode.ExprProds == nil {
		// Not in the replaying mode, choose one node using MABChooseARM and proceed.
		//fmt.Printf("\n\n\nLooking for root: %s, depth: %d\n\n\n", root, depth)
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
		//fmt.Printf("\n\n\nReplaying mode: Looking for root: %s, depth: %d\n\n\n", root, depth)
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
			//fmt.Printf("Getting prod.Items: %s\n", item.Value)

			var v []string

			tokenStr := item.Value

			if depth < 0 {
				if tokenStr == "expr" {
					ret = append(ret, " 100 ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				} else if tokenStr == "select_no_parens" {
					ret = append(ret, " select 'abc' ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				} else if tokenStr == "select_with_parens" {
					ret = append(ret, " (select 'abc') ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				} else if tokenStr == "operand" {
					ret = append(ret, " 100 ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				}
			}

			switch tokenStr {
			case "OP_NOTEQUAL":
				v = []string{" != "}
			case "OP_SEMI":
				v = []string{" ; "}
			case "BIGINT":
				v = []string{" 0 "}
			case "OP_GREATERTHAN":
				v = []string{" > "}
			case "OP_LESSTHAN":
				v = []string{" < "}
			case "OP_GREATEREQ":
				v = []string{" >= "}
			case "OP_ADD":
				v = []string{" + "}
			case "OP_SUB":
				v = []string{" - "}
			case "OP_MUL":
				v = []string{" * "}
			case "OP_MOD":
				v = []string{" % "}
			case "OP_XOR":
				v = []string{" ^ "}
			case "OP_COMMA":
				v = []string{" , "}
			case "OP_LESSEQ":
				v = []string{" <= "}
			case "OP_RP":
				v = []string{" ) "}
			case "OP_LP":
				v = []string{" ( "}
			case "OP_LBRACKET":
				v = []string{" [ "}
			case "OP_RBRACKET":
				v = []string{" ] "}
			case "OP_DIVIDE":
				v = []string{" / "}
			case "OP_EQUAL":
				v = []string{" = "}
			case "INTLITERAL":
				v = []string{" 100 "}
			case "FLOATLITERAL":
				v = []string{" 0.0 "}
			case "STRINGLITERAL":
				v = []string{" 'abc' "}
			case "IDENTIFIER":
				v = []string{" v0 "}
			default:

				if _, ok := r.GetAllProds()[tokenStr]; !ok {
					// Terminating token.
					v = []string{tokenStr}
				} else {
					// Non-terminating token.
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
							v = GenerateMySQLSquirrel(r, item.Value, newChildPathNode, rootHash, depth-1, rootDepth)
						} else {
							// If not choosing the complex rules, depth not decrease.
							v = GenerateMySQLSquirrel(r, item.Value, newChildPathNode, rootHash, depth, rootDepth)
						}
					} else {
						if replayExprIdx >= len(rootPathNode.Children) {
							//fmt.Printf("\n\n\nERROR: The replaying node is not consistent with the saved structure. \n\n\n")
							//fmt.Printf("Root: %s", root)
							//fmt.Printf("len(rootPathNode.Children): %d\n", len(rootPathNode.Children))
							//fmt.Printf("replayExprIdx %d\n", replayExprIdx)
							return nil
						}
						newChildPathNode = rootPathNode.Children[replayExprIdx]
						replayExprIdx += 1
						// We won't decrease depth number in replaying mode.
						v = GenerateMySQLSquirrel(r, item.Value, newChildPathNode, rootHash, depth, rootDepth)
					}
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
	//fmt.Printf("\n%sLevel: %d, root: %s, allProds: %v", strings.Repeat(" ", 9-depth), depth, root, curChosenRule.Items)
	return ret
}
