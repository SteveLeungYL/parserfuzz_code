package rsgGenerator

import (
	"encoding/json"
	"fmt"
	"github.com/rsg/yacc"
	"os"
	"strings"
)

func GenerateTiDB(r RSGInterface, root string, rootPathNode *PathNode, parentHash uint32, depth int, rootDepth int) []string {

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

			if depth < 0 {
				if tokenStr == "SelectStmt" {
					ret = append(ret, " SELECT 'abc' ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				} else if tokenStr == "Expression" {
					ret = append(ret, " True ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				} else if tokenStr == "SimpleExpr" {
					ret = append(ret, " True ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				} else if tokenStr == "SubSelect" {
					ret = append(ret, " ( SELECT TRUE ) ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				} else if tokenStr == "WithClause" {
					ret = append(ret, " ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				} else if tokenStr == "TableRef" {
					ret = append(ret, " v0 ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				}
			}

			switch tokenStr {
			case "Identifier":
				v = []string{"v0"}
			case "StringLiteral":
				v = []string{`'string'`}
			case "stringLit":
				v = []string{`'string'`}
			case "not":
				v = []string{"NOT"}
			case "not2":
				v = []string{"NOT"}
			case "falseKwd":
				v = []string{"FALSE"}
			case "trueKwd":
				v = []string{"TRUE"}
			case "intLit":
				v = []string{fmt.Sprint(r.Intn(1000) - 500)}
			case "floatLit":
				v = []string{fmt.Sprint(r.Float64())}
			case "decLit":
				v = []string{fmt.Sprint(r.Float64())}
			case "hexLit":
				v = []string{"'ac12'"}
			case "bitLit":
				v = []string{"b'01'"}
			case "BITCONST":
				v = []string{`B'10010'`}
			case "andnot":
				v = []string{"&^"}
			case "assignmentEq":
				v = []string{":="}
			case "eq":
				v = []string{"="}
			case "ge":
				v = []string{">="}
			case "le":
				v = []string{"<="}
			case "jss":
				v = []string{"->"}
			case "juss":
				v = []string{"->>"}
			case "lsh":
				v = []string{"<<"}
			case "neq":
				v = []string{"!="}
			case "neqSynonym":
				v = []string{"<>"}
			case "nulleq":
				v = []string{"<=>"}
			case "paramMarker":
				v = []string{"?"}
			case "rsh":
				v = []string{">>"}
			default:

				tokenWithoutQuote := strings.ReplaceAll(item.Value, "\"", "")
				if mapped_val, ok := r.GetMappedKeywords()[tokenWithoutQuote]; ok {
					//fmt.Printf("Rewriting item.Value from %s to %s\n\n", tokenWithoutQuote, mapped_val)
					v = []string{mapped_val.(string)}
				} else {
					isFirstQuote := false
					// The only way to get a rune from the string seems to be retrieved from for
					if item.Value[0] == '"' {
						isFirstQuote = true
					}

					if isFirstQuote {
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
							v = GenerateTiDB(r, item.Value, newChildPathNode, rootHash, depth-1, rootDepth)
						} else {
							// If not choosing the complex rules, depth not decrease.
							v = GenerateTiDB(r, item.Value, newChildPathNode, rootHash, depth, rootDepth)
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
						v = GenerateTiDB(r, item.Value, newChildPathNode, rootHash, depth, rootDepth)
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
	return ret
}

func MapTidbKeywords() map[string]interface{} {

	var mapped_keywords map[string]interface{}

	dat, err := os.ReadFile("./tidb_keyword_mapping.json")
	if err != nil {
		panic(err)
	}

	err = json.Unmarshal(dat, &mapped_keywords)
	if err != nil {
		panic(err)
	}

	if len(mapped_keywords) == 0 {
		panic("Error: Read mapped keywords from TiDB database failed.")
	}

	return mapped_keywords
}
