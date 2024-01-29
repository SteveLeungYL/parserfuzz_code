package rsgGenerator

import (
	"fmt"
	"github.com/rsg/yacc"
	"unicode"
)

func GenerateSqlite(r RSGInterface, root string, rootPathNode *PathNode, parentHash uint32, depth int, rootDepth int) []string {

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

	// Initialize to an empty slice instead of nil because nil means error.
	ret := make([]string, 0)

	//fmt.Printf("\n\n\n From root: %s, getting allProds size: %d \n\n\n", root, len(allProds))
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
	// It is OK to be empty Items. Return empty ret then.
	// Attention: return nil means error.
	for _, item := range curChosenRule.Items {
		switch item.Typ {
		case yacc.TypLiteral:
			// Single quoted characters
			// remove the quote, directly paste the string.
			v := item.Value[1 : len(item.Value)-1]
			ret = append(ret, v)
			continue
		case yacc.TypToken:
			//fmt.Printf("Getting curChosenRule.Items: %s\n", item.Value)

			var v []string

			switch item.Value {

			case "SEMI":
				ret = append(ret, ";")
				continue
			case "LP":
				ret = append(ret, "(")
				continue
			case "RP":
				ret = append(ret, ")")
				continue
			case "COMMA":
				ret = append(ret, ",")
				continue
			case "LIKE_KW":
				ret = append(ret, " LIKE ")
				continue
			case "MATCH":
				ret = append(ret, " MATCH ")
				continue
			case "NE":
				ret = append(ret, "!=")
				continue
			case "EQ":
				ret = append(ret, "=")
				continue
			case "GT":
				ret = append(ret, ">")
				continue
			case "LE":
				ret = append(ret, "<=")
				continue
			case "LT":
				ret = append(ret, "<")
				continue
			case "GE":
				ret = append(ret, ">=")
				continue
			case "COLUMNKW":
				ret = append(ret, " COLUMN ")
				continue
			case "CTIME_KW":
				// Not sure.
				ret = append(ret, " '' ")
				continue
			case "BITAND":
				ret = append(ret, " & ")
				continue
			case "BITOR":
				ret = append(ret, " | ")
				continue
			case "LSHIFT":
				ret = append(ret, "<<")
				continue
			case "RSHIFT":
				ret = append(ret, ">>")
				continue
			case "PLUS":
				ret = append(ret, "+")
				continue
			case "MINUS":
				ret = append(ret, "-")
				continue
			case "STAR":
				ret = append(ret, "*")
				continue
			case "SLASH":
				ret = append(ret, "/")
				continue
			case "REM":
				ret = append(ret, "%")
				continue
			case "CONCAT":
				ret = append(ret, " || ")
				continue
			case "PTR":
				ret = append(ret, "->")
				continue
			case "BITNOT":
				ret = append(ret, "~")
				continue
			case "JOIN_KW":
				switch r.Intn(3) {
				case 0:
					ret = append(ret, " LEFT ")
					break
				case 1:
					ret = append(ret, " RIGHT ")
					break
				case 2:
					ret = append(ret, " FULL ")
					break
				}
				continue
			case "DOT":
				ret = append(ret, ".")
				continue
			case "TRUEFALSE":
				ret = append(ret, "TRUE")
				continue
			case "UMINUS":
				ret = append(ret, "-")
				continue
			case "UPLUS":
				ret = append(ret, "+")
				continue
			case "ID":
				ret = append(ret, "v0")
				continue
			case "id":
				ret = append(ret, "v0")
				continue
			case "typename":
				switch r.Intn(3) {
				case 0:
					ret = append(ret, " INTEGER ")
					break
				case 1:
					ret = append(ret, " FLOAT ")
					break
				case 2:
					ret = append(ret, " STRING ")
					break
				}
				continue
			case "STRING":
				ret = append(ret, "'abc'")
				continue
			case "VARIABLE":
				ret = append(ret, " 0.0 ")
				continue
			case "AUTOINCR":
				ret = append(ret, "AUTOINCREMENT")
				continue
			case "FLOAT":
				ret = append(ret, "0.0")
				continue
			case "BLOB":
				ret = append(ret, "''")
				continue
			case "INTEGER":
				ret = append(ret, "0")
				continue
			case "FUNC":
				// Use unknown function.
				ret = append(ret, "UNKNOWN")
				continue

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
						v = GenerateSqlite(r, item.Value, newChildPathNode, rootHash, depth-1, rootDepth)
					} else {
						// If not choosing the complex rules, depth not decrease.
						v = GenerateSqlite(r, item.Value, newChildPathNode, rootHash, depth, rootDepth)
					}
				} else {
					if replayExprIdx >= len(rootPathNode.Children) {
						fmt.Printf("\n\n\nERROR: The replaying node is not consistent with the saved structure. \n\n\n")
						return nil
					}
					newChildPathNode = rootPathNode.Children[replayExprIdx]
					replayExprIdx += 1
					// We won't decrease depth number in replaying mode.
					v = GenerateSqlite(r, item.Value, newChildPathNode, rootHash, depth, rootDepth)
				}

				//fmt.Printf("\n\n\nFor root: %s, getting child node: %s, child Node: %v\n\n\n", root, item.Value, newChildPathNode.ExprProds)
			}
			if v == nil {
				// Return nil means error.
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
