// Copyright 2016 The Cockroach Authors.
//
// Use of this software is governed by the Business Source License
// included in the file licenses/BSL.txt.
//
// As of the Change Date specified in that file, in accordance with
// the Business Source License, use of this software will be governed
// by the Apache License, Version 2.0, included in the file
// licenses/APL.txt.

package main

import (
	"encoding/json"
	"fmt"
	"github.com/rsg/yacc"
	"math"
	"math/rand"
	"os"
	"strings"
	"unicode"
)

// The PathNode is the data structure that used to save
// the whole chosen query path for the RSG generated query.
// The goal of this structure is to be memory efficient and
// simple, and it should be mutable.
type PathNode struct {
	Id        int
	Parent    *PathNode
	ExprProds *yacc.ExpressionNode
	Children  []*PathNode
}

// RSG is a random syntax generator.
type RSG struct {
	Rnd *rand.Rand

	prods     map[string][]*yacc.ExpressionNode
	termProds map[string][]*yacc.ExpressionNode // prods that lead to token termination

	curChosenPath   []*PathNode
	allSavedPath    map[string][][]*PathNode
	curMutatingType string
	epsilon         float64
	pathId          int
}

// NewRSG creates a random syntax generator from the given random seed and
// yacc file.
func NewRSG(seed int64, y string, dbmsName string, epsilon float64) (*RSG, error) {

	// Default epsilon = 0.3
	if epsilon == 0.0 {
		epsilon = 0.3
	}

	tree, err := yacc.Parse("sql", y, dbmsName)
	if err != nil {
		fmt.Printf("\nGetting error: %v\n\n", err)
		return nil, err
	}
	rsg := RSG{
		Rnd:           rand.New(&lockedSource{src: rand.NewSource(seed).(rand.Source64)}),
		prods:         make(map[string][]*yacc.ExpressionNode), // Used to save all the grammar edges
		termProds:     make(map[string][]*yacc.ExpressionNode), // Used to save only the terminating edges
		curChosenPath: []*PathNode{},
		allSavedPath:  make(map[string][][]*PathNode),
		epsilon:       epsilon,
	}

	// Construct all the possible Productions (Grammar Edges)
	for _, prod := range tree.Productions {
		_, ok := rsg.prods[prod.Name]
		if ok {
			for _, curExpr := range prod.Expressions {
				rsg.prods[prod.Name] = append(rsg.prods[prod.Name], curExpr)
			}
		} else {
			rsg.prods[prod.Name] = prod.Expressions
		}
	}

	// Construct the terminating Productions (Grammar Edges)
	for rootName, rootProds := range rsg.prods {
		for _, prod := range rootProds {
			isTerm := true
			for _, curNode := range prod.Items {
				if !isTerm {
					// If the current path is already
					// classified as non-term
					// Do not continue
					break
				}
				childProds, ok := rsg.prods[curNode.Value]
				if ok {
					// this is not a terminating child node.
					// search one more level.
					// Thoroughly go through all the possible
					// choices from the sub-node.
					for _, childProd := range childProds {
						if !isTerm {
							// If the current path is already
							// classified as non-term
							// Do not continue
							break
						}
						for _, childNode := range childProd.Items {
							if !isTerm {
								// If the current path is already
								// classified as non-term
								// Do not continue
								break
							}
							_, childOk := rsg.prods[childNode.Value]
							if childOk {
								// Find the nested child node.
								// Not a terminating node.
								// Do not continue
								isTerm = false
								break
							}
						}
					}
				} // finished searching the one child node.
				if !isTerm {
					break
				}
			} // finished searching all the child node.
			if isTerm {
				prod.IsTermNode = true
				rsg.termProds[rootName] = append(rsg.termProds[rootName], prod)
				//fmt.Printf("\n\n\nDEBUG: Getting terminating root: %s, prod: %v\n\n\n", rootName, prod)
			} else {
				prod.IsTermNode = false
			}
		}
	}

	return &rsg, nil
}

func (r *RSG) GatherAllPathNodes(curPathNode *PathNode) []*PathNode {
	// Recursive function. May not be optimal
	var pathArray = []*PathNode{}
	if curPathNode == nil {
		// Return empty
		fmt.Printf("\n\n\nError: Getting nil curPathNode from GatherAllPathNodes\n\n\n")
		return pathArray
	}
	pathArray = append(pathArray, curPathNode)
	for _, curChild := range curPathNode.Children {
		childPathArray := r.GatherAllPathNodes(curChild)
		pathArray = append(pathArray, childPathArray...)
	}

	return pathArray
}

func (r *RSG) DumpParserRuleMap(outFile string) {

	resJsonStr, err := json.Marshal(r.prods)

	if err != nil {
		fmt.Printf("\n\n\nError: Cannot generate the r.prods JSON file. \n\n\n")
	}

	f, err := os.OpenFile(outFile, os.O_TRUNC|os.O_CREATE|os.O_WRONLY, 0644)
	defer func(f *os.File) {
		_ = f.Close()
	}(f)

	if err != nil {
		fmt.Printf("\n\n\nError: Cannot write to parser_rule.json file. \n\n\n")
	}
	_, _ = f.Write(resJsonStr)

}

func (r *RSG) ClearChosenExpr() {
	// clear the map
	r.curChosenPath = []*PathNode{}
	r.pathId = 0
}

func (r *RSG) IncrementSucceed() {

	//fmt.Printf("\nSaving r.curChosenPath size: %d, root: %v\n\n\n", len(r.curChosenPath), r.curChosenPath[0].ExprProds)
	for _, curPath := range r.curChosenPath {
		prod := curPath.ExprProds
		//fmt.Printf("\nGetting ExprProds: %v\n", prod)
		if prod == nil {
			continue
		}
		prod.HitCount++
		prod.RewardScore =
			(float64(prod.HitCount-1)/float64(prod.HitCount))*prod.RewardScore + (1.0/float64(prod.HitCount))*1.0
		//fmt.Printf("For expr: %q, hit_count: %d, score: %d\n", prod.Items, prod.HitCount, prod.RewardScore)
	}

	// Save the new nodes to the seed.
	if len(r.curChosenPath) != 0 {
		//fmt.Printf("\n\n\nSaving with type: %s\n\n\n", r.curMutatingType)
		r.allSavedPath[r.curMutatingType] = append(r.allSavedPath[r.curMutatingType], r.curChosenPath)
		//fmt.Printf("\nallSavedPath size: %d\n", len(r.allSavedPath[r.curMutatingType]))
	}
	r.ClearChosenExpr()

}

func (r *RSG) IncrementFailed() {
	for _, curPath := range r.curChosenPath {
		prod := curPath.ExprProds
		if prod == nil {
			continue
		}
		prod.HitCount++
		prod.RewardScore =
			(float64(prod.HitCount-1)/float64(prod.HitCount))*prod.RewardScore + (1.0/float64(prod.HitCount))*0.0
		//fmt.Printf("For expr: %q, hit_count: %d, score: %d\n", prod.Items, prod.HitCount, prod.RewardScore)
	}

	r.ClearChosenExpr()
}

func (r *RSG) argMax(rewards []float64) int {

	var maxIdx []int
	var maxReward = -1.0

	for idx, reward := range rewards {
		if reward > maxReward {
			maxReward = reward
			maxIdx = []int{idx}
		} else if reward == maxReward {
			maxIdx = append(maxIdx, idx)
		} else {
			continue
		}
	}

	resIdx := r.Rnd.Intn(len(maxIdx))
	return maxIdx[resIdx]
}

func (r *RSG) MABChooseArm(prods []*yacc.ExpressionNode, root string) *yacc.ExpressionNode {

	resIdx := 0
	for trial := 0; trial < 10; trial++ {
		if r.Rnd.Float64() > r.epsilon {
			//fmt.Printf("\n\n\nUsing ArgMax. \n\n\n")
			var rewards []float64
			for _, prod := range prods {
				rewards = append(rewards, prod.RewardScore)
			}
			resIdx = r.argMax(rewards)
			//fmt.Printf("\n\n\nusing resIdx: %d \n\n\n", resIdx)
		} else {
			// Random choice.
			//fmt.Printf("\n\n\nUsing Random. \n\n\n")
			resIdx = r.Rnd.Intn(len(prods))
			//fmt.Printf("\n\n\nusing resIdx: %d \n\n\n", resIdx)
		}

		resProd := prods[resIdx]

		isRetry := false
		for _, childProd := range resProd.Items {
			if childProd.Value == root {
				if r.Rnd.Intn(10) != 0 {
					// 9/10 chances, do not use nested token.
					isRetry = true
					//fmt.Printf("\n\n\nFrom root:%s, getting recursive child: %v\n\n\n", root, resProd.Items)
				}
			}
		}
		if isRetry {
			continue
		} else {
			// Decided to choose the current path.
			// Return the resProd.
			break
		}
	}

	//fmt.Printf("\n\n\nFrom root: %s, Chossing resProd: %d. \n\n\n", root, resIdx)
	return prods[resIdx]
}

// Generate generates a unique random syntax from the root node. At most depth
// levels of token expansion are performed. An empty string is returned on
// error or if depth is exceeded. Generate is safe to call from multiple
// goroutines. If Generate is called more times than it can generate unique
// output, it will block forever.
func (r *RSG) Generate(root string, dbmsName string, depth int) string {
	var s = ""
	// Mark the current mutating types
	// The successfully generated and executed queries would be saved
	// based on the root type.
	r.curMutatingType = root
	for i := 0; i < 1000; i++ {
		s = strings.Join(r.generate(root, dbmsName, depth, depth), " ")
		//fmt.Printf("\n\n\nFrom root, %s, depth: %d, getting stmt: %s\n\n\n", root, depth, s)

		if s != "" {
			s = strings.Replace(s, "_LA", "", -1)
			s = strings.Replace(s, " AS OF SYSTEM TIME \"string\"", "", -1)
			return s
		}
	}
	fmt.Printf("\n\n\ncouldn't find unique string for root: %s\n\n\n", root)
	return s
}

func (r *RSG) generateMySQL(root string, depth int, rootDepth int) []string {
	// Initialize to an empty slice instead of nil because nil is the signal
	// that the depth has been exceeded.
	ret := make([]string, 0)
	prods := r.prods[root]
	if len(prods) == 0 {
		return []string{r.formatTokenValue(root)}
	}

	prod := r.MABChooseArm(prods, root)

	if prod == nil {
		return nil
	}

	for _, item := range prod.Items {
		switch item.Typ {
		case yacc.TypLiteral:
			v := item.Value[1 : len(item.Value)-1]
			ret = append(ret, v)
			continue
		case yacc.TypToken:
			//fmt.Printf("Getting prod.Items: %s\n", item.Value)

			var v []string

			switch item.Value {
			case "ident":
				v = []string{"ident"}

			case "expr":
				if depth == 0 {
					v = []string{"TRUE"}
				} else {
					v = r.generateMySQL(item.Value, depth-1, rootDepth)
				}

			default:
				if depth == 0 {
					return nil
				}
				v = r.generateMySQL(item.Value, depth-1, rootDepth)
			}
			if v == nil {
				continue
			}
			ret = append(ret, v...)
		default:
			panic("unknown item type")
		}
	}
	return ret
}

func (r *RSG) generatePostgres(root string, depth int, rootDepth int) []string {
	// Initialize to an empty slice instead of nil because nil is the signal
	// that the depth has been exceeded.
	ret := make([]string, 0)
	prods := r.prods[root]
	if len(prods) == 0 {
		return []string{r.formatTokenValue(root)}
	}

	prod := r.MABChooseArm(prods, root)

	if prod == nil {
		return nil
	}

	for _, item := range prod.Items {
		switch item.Typ {
		case yacc.TypLiteral:
			v := item.Value[1 : len(item.Value)-1]
			ret = append(ret, v)
			continue
		case yacc.TypToken:
			//fmt.Printf("Getting prod.Items: %s\n", item.Value)

			var v []string

			switch item.Value {
			case "IDENT":
				v = []string{"ident"}

				// Skip through a_expr and b_expr. Seems changing a_expr and b_expr
				// to d_expr would cause a lot of syntax errors.
				/*
				   //case "a_expr":
				       //fallthrough
				   //case "b_expr":
				       //fallthrough
				*/
				// If the recursion reaches specific depth, do not expand on `c_expr`,
				// directly refer to `d_expr`.
			case "c_expr":
				if (rootDepth-3) > 0 &&
					depth > (rootDepth-3) {
					v = r.generatePostgres(item.Value, depth-1, rootDepth)
				} else if depth > 0 {
					v = r.generatePostgres("SCONST", depth-1, rootDepth)
				} else {
					v = []string{`'string'`}
				}

				if v == nil {
					v = []string{`'string'`}
				}

			case "SCONST":
				v = []string{`'string'`}
			case "ICONST":
				v = []string{fmt.Sprint(r.Intn(1000) - 500)}
			case "FCONST":
				v = []string{fmt.Sprint(r.Float64())}
			case "BCONST":
				v = []string{`b'bytes'`}
			case "XCONST":
				v = []string{`B'10010'`}
			default:
				if depth == 0 {
					return nil
				}
				v = r.generatePostgres(item.Value, depth-1, rootDepth)
			}
			if v == nil {
				return nil
			}
			ret = append(ret, v...)
		default:
			panic("unknown item type")
		}
	}
	return ret
}

func (r *RSG) generateSqliteBison(root string, depth int, rootDepth int) []string {
	// Initialize to an empty slice instead of nil because nil is the signal
	// that the depth has been exceeded.
	ret := make([]string, 0)
	prods := r.prods[root]
	if len(prods) == 0 {
		return []string{r.formatTokenValue(root)}
	}

	prod := r.MABChooseArm(prods, root)

	//fmt.Printf("\n\n\nFrom node: %s, getting stmt: %v\n\n\n", root, prod)

	if prod == nil {
		return nil
	}

	for _, item := range prod.Items {
		switch item.Typ {
		case yacc.TypLiteral:
			v := item.Value[1 : len(item.Value)-1]
			ret = append(ret, v)
			continue
		case yacc.TypToken:

			var v []string

			switch item.Value {

			case "IDENTIFIER":
				{
					v = []string{"v0"}
				}
			case "STRING":
				{
					v = []string{`'string'`}
				}

			default:
				if depth == 0 {
					return ret
				}
				v = r.generateSqliteBison(item.Value, depth-1, rootDepth)
			}
			if v == nil {
				fmt.Printf("\n\n\nFor root %s, item,Value: %s, reaching depth\n\n\n", root, item.Value)
				return nil
			}
			ret = append(ret, v...)
		default:
			panic("unknown item type")
		}
	}
	return ret
}

func (r *RSG) generateSqlite(root string, parentPathNode *PathNode, depth int, rootDepth int) []string {
	// Initialize to an empty slice instead of nil because nil is the signal
	// that the depth has been exceeded.

	//fmt.Printf("\n\n\nLooking for root: %s\n\n\n", root)
	replayingMode := false

	if parentPathNode == nil {
		fmt.Printf("\n\n\nError: parentPathNode is nil. \n\n\n")
		// Return nil is different from return an empty array.
		// Return nil represent error.
		return nil
	}

	ret := make([]string, 0)

	if depth <= -6 {
		// Return nil represent error.
		return nil
	}

	//fmt.Printf("\n\n\n From root: %s, getting prods size: %d \n\n\n", root, len(prods))
	var prod *yacc.ExpressionNode
	if parentPathNode.ExprProds == nil {
		// Not in the replaying mode, randomly choose one node and proceed.
		replayingMode = false

		// Choose terminating node, if depth reached.
		var prods []*yacc.ExpressionNode
		if depth <= 0 && r.Rnd.Intn(100) < 95 {
			var ok bool
			prods, ok = r.termProds[root]
			if !ok {
				// fallback to the original non-term tokens
				//fmt.Printf("\n\n\nDebug: For root: %s, cannot find any terminating rules. \n\n\n", root)
				prods = r.prods[root]
			}
		} else {
			prods = r.prods[root]
		}
		prod = r.MABChooseArm(prods, root)
		parentPathNode.ExprProds = prod
		parentPathNode.Children = []*PathNode{}
	} else {
		// Replay mode, directly reuse the previous chosen expressions.
		replayingMode = true
		prod = parentPathNode.ExprProds
	}

	if prod == nil {
		fmt.Printf("\n\n\nERROR: getting nil prod. \n\n\n")
		return nil
	}

	replayExprIdx := 0
	for _, item := range prod.Items {
		switch item.Typ {
		case yacc.TypLiteral:
			// Single quoted characters
			// remove the quote, directly paste the string.
			v := item.Value[1 : len(item.Value)-1]
			ret = append(ret, v)
			continue
		case yacc.TypToken:
			//fmt.Printf("Getting prod.Items: %s\n", item.Value)

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
			case "BITNOT":
				ret = append(ret, "~")
				continue
			case "JOIN_KW":
				switch r.Rnd.Intn(3) {
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
				switch r.Rnd.Intn(3) {
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
				ret = append(ret, "0.0")
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
				ret = append(ret, "COUNT")
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
						Id:        r.pathId,
						Parent:    parentPathNode,
						ExprProds: nil,
						Children:  []*PathNode{},
					}
					r.pathId += 1
					parentPathNode.Children = append(parentPathNode.Children, newChildPathNode)
					v = r.generateSqlite(item.Value, newChildPathNode, depth-1, rootDepth)
				} else {
					if replayExprIdx >= len(parentPathNode.Children) {
						fmt.Printf("\n\n\nERROR: The replaying node is not consistent with the saved structure. \n\n\n")
						return nil
					}
					newChildPathNode = parentPathNode.Children[replayExprIdx]
					replayExprIdx += 1
					// We won't decrease depth number in replaying mode.
					v = r.generateSqlite(item.Value, newChildPathNode, depth, rootDepth)
				}

				//fmt.Printf("\n\n\nFor root: %s, getting child node: %s, child Node: %v\n\n\n", root, item.Value, newChildPathNode.ExprProds)
			}
			if v == nil {
				return nil
			}
			ret = append(ret, v...)
		default:
			panic("unknown item type")
		}
	}
	//fmt.Printf("\n%sLevel: %d, root: %s, prods: %v", strings.Repeat(" ", 9-depth), depth, root, prod.Items)
	return ret
}

func (r *RSG) generateCockroach(root string, depth int, rootDepth int) []string {
	// Initialize to an empty slice instead of nil because nil is the signal
	// that the depth has been exceeded.
	ret := make([]string, 0)
	prods := r.prods[root]
	if len(prods) == 0 {
		return []string{root}
	}

	var prod *yacc.ExpressionNode = nil
	for idx := 0; idx < 10; idx++ {
		// Check whether the chosen prod contains unimplemented or error related
		// rule. If yes, do not choose this path.

		tmpProd := r.MABChooseArm(prods, root)

		if strings.Contains(tmpProd.Command, "unimplemented") && !strings.Contains(tmpProd.Command, "FORCE DOC") {
			continue
		}
		if strings.Contains(tmpProd.Command, "SKIP DOC") {
			continue
		}

		isError := false
		for _, item := range tmpProd.Items {
			if item.Value == "error" {
				isError = true
				break
			}
		}
		if !isError {
			prod = tmpProd
			break
		}

		continue
	}

	if prod == nil {
		return nil
	}

	for _, item := range prod.Items {
		switch item.Typ {
		case yacc.TypLiteral:
			v := item.Value[1 : len(item.Value)-1]
			ret = append(ret, v)
			continue
		case yacc.TypToken:
			var v []string
			switch item.Value {
			case "IDENT":
				v = []string{"ident"}

				// Skip through a_expr and b_expr. Seems changing a_expr and b_expr
				// to d_expr would cause a lot of syntax errors.
				/*
				   //case "a_expr":
				       //fallthrough
				   //case "b_expr":
				       //fallthrough
				*/
				// If the recursion reaches specific depth, do not expand on `c_expr`,
				// directly refer to `d_expr`.
			case "c_expr":
				if (rootDepth-3) > 0 &&
					depth > (rootDepth-3) {
					v = r.generateCockroach(item.Value, depth-1, rootDepth)
				} else if depth > 0 {
					v = r.generateCockroach("d_expr", depth-1, rootDepth)
				} else {
					v = []string{`'string'`}
				}

				if v == nil {
					v = []string{`'string'`}
				}

			// If the recursion reaches specific depth, do not expand on `d_expr`,
			// directly use string literals.
			case "d_expr":
				if (rootDepth-5) > 0 &&
					depth > (rootDepth-5) {
					v = r.generateCockroach(item.Value, depth-1, rootDepth)
				} else {
					v = []string{`'string'`}
				}

				if v == nil {
					v = []string{`'string'`}
				}

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
			default:
				if depth == 0 {
					return nil
				}
				v = r.generateCockroach(item.Value, depth-1, rootDepth)
			}
			if v == nil {
				return nil
			}
			ret = append(ret, v...)
		default:
			panic("unknown item type")
		}
	}
	return ret
}

func (r *RSG) deepCopyPathNode(srcNode *PathNode, destParentNode *PathNode) *PathNode {

	// Recursive function. May not be optimal
	if srcNode == nil {
		// Return empty
		fmt.Printf("\n\n\nError: In deepCopyPathNode, getting srcNode is nil. \n\n\n")
		os.Exit(1)
	}

	newDestPathNode := &PathNode{
		Id:        srcNode.Id,
		Parent:    destParentNode,
		ExprProds: srcNode.ExprProds,
		Children:  []*PathNode{},
	}

	for _, curChild := range srcNode.Children {
		newDestChild := r.deepCopyPathNode(curChild, newDestPathNode)
		newDestPathNode.Children = append(newDestPathNode.Children, newDestChild)
	}

	return newDestPathNode
}

func (r *RSG) retrieveExistingPathNode(root string) []*PathNode {

	_, pathExisted := r.allSavedPath[root]
	if !pathExisted {
		fmt.Printf("Fatal Error. Cannot find the PathNode with %s\n\n\n", root)
		os.Exit(1)
	}

	srcPath := r.allSavedPath[root][r.Rnd.Intn(len(r.allSavedPath[root]))]
	if len(srcPath) == 0 {
		fmt.Printf("\n\n\nERROR: Saved an empty path nodes to the interesting seeds. "+
			"Root: %s"+
			"\n\n\n", root)
	}

	// Deep Copy the source path from root
	targetPathRoot := r.deepCopyPathNode(srcPath[0], nil)

	targetPath := r.GatherAllPathNodes(targetPathRoot)

	if len(targetPath) == 0 {
		fmt.Printf("\n\n\n Error, getting targetPath len == 0 in the retrieveExistingPathNode. \n\n\n")
		os.Exit(1)
	}

	return targetPath
}

func (r *RSG) generate(root string, dbmsName string, depth int, rootDepth int) []string {

	r.ClearChosenExpr()

	var rootPathNode *PathNode
	_, pathExisted := r.allSavedPath[root]

	if pathExisted &&
		len(r.allSavedPath[root]) != 0 &&
		r.Rnd.Intn(3) != 0 {
		// 2/3 chances.
		// Replaying mode.

		// Retrieve a deep copied from the existing seed.
		newPath := r.retrieveExistingPathNode(root)

		// Choose a random node to mutate.
		// Do not choose the root to mutate
		var mutateNode *PathNode
		if len(newPath) == 1 {
			mutateNode = newPath[0]
		} else {
			mutateNode = newPath[r.Rnd.Intn(len(newPath)-1)+1]
		}

		// Remove the ExprProds and the Children,
		// so the generate function would be required to
		// randomly generate any nodes.
		// This operation could free some not-used PathNode
		// from the newPath.
		//fmt.Printf("\n\n\nDebug: Choosing mutate node: %v\n\n\n", mutateNode.ExprProds)
		mutateNode.ExprProds = nil
		mutateNode.Children = []*PathNode{}

		rootPathNode = newPath[0]

	} else {
		// Construct a new statement.
		rootPathNode = &PathNode{
			Id:        r.pathId,
			Parent:    nil,
			ExprProds: nil,
			Children:  []*PathNode{},
		}
	}

	var resStr []string

	if dbmsName == "sqlite" {
		resStr = r.generateSqlite(root, rootPathNode, depth, rootDepth)
	} else if dbmsName == "sqlite_bison" {
		// TODO: Implement replaying mode.
		resStr = r.generateSqliteBison(root, depth, rootDepth)
	} else if dbmsName == "postgres" {
		// TODO: Implement replaying mode.
		resStr = r.generatePostgres(root, depth, rootDepth)
	} else if dbmsName == "cockroachdb" {
		// TODO: Implement replaying mode.
		resStr = r.generateCockroach(root, depth, rootDepth)
	} else if dbmsName == "mysql" {
		// TODO: Implement replaying mode.
		resStr = r.generateMySQL(root, depth, rootDepth)
	} else {
		panic(fmt.Sprintf("unknown dbms name: %s", dbmsName))
	}

	r.curChosenPath = r.GatherAllPathNodes(rootPathNode)

	return resStr
}

func (r *RSG) formatTokenValue(in string) string {

	if strings.HasSuffix(in, "_P") {
		in = in[:len(in)-2]
	}

	return in

}

// Intn returns a random int.
func (r *RSG) Intn(n int) int {
	return r.Rnd.Intn(n)
}

// Int63 returns a random int64.
func (r *RSG) Int63() int64 {
	return r.Rnd.Int63()
}

// Float64 returns a random float. It is sometimes +/-Inf, NaN, and attempts to
// be distributed among very small, large, and normal scale numbers.
func (r *RSG) Float64() float64 {
	v := r.Rnd.Float64()*2 - 1
	switch r.Rnd.Intn(10) {
	case 0:
		v = 0
	case 1:
		v = math.Inf(1)
	case 2:
		v = math.Inf(-1)
	case 3:
		v = math.NaN()
	case 4, 5:
		i := r.Rnd.Intn(50)
		v *= math.Pow10(i)
	case 6, 7:
		i := r.Rnd.Intn(50)
		v *= math.Pow10(-i)
	}
	return v
}

// lockedSource is a thread safe math/rand.Source. See math/rand/rand.go.
type lockedSource struct {
	src rand.Source64
}

func (r *lockedSource) Int63() (n int64) {
	n = r.src.Int63()
	return
}

func (r *lockedSource) Uint64() (n uint64) {
	n = r.src.Uint64()
	return
}

func (r *lockedSource) Seed(seed int64) {
	r.src.Seed(seed)
}
