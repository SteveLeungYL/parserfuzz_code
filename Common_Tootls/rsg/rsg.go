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

// RSG is a random syntax generator.
type RSG struct {
	Rnd *rand.Rand

	prods map[string][]*yacc.ExpressionNode

	curChosenExpr map[*yacc.ExpressionNode]bool
	epsilon       float64
}

// NewRSG creates a random syntax generator from the given random seed and
// yacc file.
func NewRSG(seed int64, y string, dbmsName string, epsilon float64) (*RSG, error) {

	// Default epsilon = 5.0
	if epsilon == 0.0 {
		epsilon = 5.0
	}

	tree, err := yacc.Parse("sql", y, dbmsName)
	if err != nil {
		fmt.Printf("\nGetting error: %v\n\n", err)
		return nil, err
	}
	rsg := RSG{
		Rnd:     rand.New(&lockedSource{src: rand.NewSource(seed).(rand.Source64)}),
		prods:   make(map[string][]*yacc.ExpressionNode),
		epsilon: epsilon,
	}
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
	return &rsg, nil
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
	r.curChosenExpr = make(map[*yacc.ExpressionNode]bool)
}

func (r *RSG) IncrementSucceed() {
	for prod := range r.curChosenExpr {
		prod.HitCount++
		prod.RewardScore =
			(float64(prod.HitCount-1)/float64(prod.HitCount))*prod.RewardScore + (1.0/float64(prod.HitCount))*1.0
		//fmt.Printf("For expr: %q, hit_count: %d, score: %d\n", prod.Items, prod.HitCount, prod.RewardScore)
	}

	r.ClearChosenExpr()
}

func (r *RSG) IncrementFailed() {
	for prod := range r.curChosenExpr {
		prod.HitCount++
		prod.RewardScore =
			(float64(prod.HitCount-1)/float64(prod.HitCount))*prod.RewardScore + (1.0/float64(prod.HitCount))*0.0
		//fmt.Printf("For expr: %q, hit_count: %d, score: %d\n", prod.Items, prod.HitCount, prod.RewardScore)
	}

	r.ClearChosenExpr()
}

func (r *RSG) argMax(rewards []float64) int {

	var maxIdx = []int{}
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

		// Save to curChosenExpr if not seen before.
		_, ok := r.curChosenExpr[resProd]
		if !ok {
			r.curChosenExpr[resProd] = true
		} else {
			// resProd used in the current stmt.
			if r.Rnd.Intn(5) != 0 {
				// 80% chances, do not use already used stmt.
				//fmt.Printf("\n\n\nSeem before\n\n\n")
				continue
			}
		}

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

	//fmt.Printf("\n\n\nChossing resProd: %d. \n\n\n", resIdx)
	return prods[resIdx]
}

// Generate generates a unique random syntax from the root node. At most depth
// levels of token expansion are performed. An empty string is returned on
// error or if depth is exceeded. Generate is safe to call from multiple
// goroutines. If Generate is called more times than it can generate unique
// output, it will block forever.
func (r *RSG) Generate(root string, dbmsName string, depth int) string {
	var s = ""
	for i := 0; i < 100; i++ {
		s = strings.Join(r.generate(root, dbmsName, depth, depth), " ")
		//fmt.Printf("\n\n\nFrom root, %s, depth: %d, getting stmt: %s\n\n\n", root, depth, s)
		//if r.seen != nil {
		//	if !r.seen[s] {
		//		r.seen[s] = true
		//	} else {
		//		//fmt.Printf("\n\n\nGetting duplicated str: %s\n\n\n", s)
		//		s = ""
		//	}
		//}
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

func (r *RSG) generateSqlite(root string, depth int, rootDepth int) []string {
	// Initialize to an empty slice instead of nil because nil is the signal
	// that the depth has been exceeded.
	ret := make([]string, 0)
	prods := r.prods[root]
	if len(prods) == 0 {
		return []string{r.formatTokenValue(root)}
	}

	prod := r.MABChooseArm(prods, root)
	if root == "expr" {
		//&& r.Rnd.Intn(3) == 0
		root = "exprFunc"
		//fmt.Printf("\n\n\nUsing exprFunc\n\n\n")
		prod = r.MABChooseArm(prods, root)
	}

	fmt.Printf("\n\n\nFrom node: %s, getting stmt: %v\n\n\n", root, prod)

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

				if depth == 0 {

					isHandle := false
					if item.Value == "expr" || item.Value == "exprnorecursive" {
						ret = append(ret, "'abc'")
						isHandle = true
					} else if item.Value == "nexprlist" || item.Value == "nexprlistnorecursive" {
						ret = append(ret, "'abc'")
						isHandle = true
					} else if item.Value == "sortlist" ||
						item.Value == "sortlistnorecursive" ||
						item.Value == "seltablist" ||
						item.Value == "seltablistnorecursive" {
						ret = append(ret, "v0")
						isHandle = true
					} else if item.Value == "selectnowith" || item.Value == "select" || item.Value == "oneselect" {
						ret = append(ret, "select 'abc'")
						isHandle = true
					} else if item.Value == "frame_bound_s" {
						ret = append(ret, "UNBOUNDED PRECEDING")
						isHandle = true
					} else if item.Value == "frame_bound_e" {
						ret = append(ret, "UNBOUNDED FOLLOWING")
						isHandle = true
					} else if item.Value == "selcollist" {
						ret = append(ret, " * ")
						isHandle = true
					} else if item.Value == "nm" {
						ret = append(ret, " v0 ")
						isHandle = true
					} else if item.Value == "term" {
						ret = append(ret, " 0.0 ")
						isHandle = true
					} else if item.Value == "window" {
						ret = append(ret, " v0 ")
						isHandle = true
					} else if item.Value == "frame_bound" {
						ret = append(ret, " CURRENT ROW ")
						isHandle = true
					} else if item.Value == "seltablist" ||
						item.Value == "seltablistnorecursive" {
						ret = append(ret, " v0 ")
						isHandle = true
					} else if item.Value == "multiselect_op" {
						ret = append(ret, " UNION ")
						isHandle = true
					}

					if isHandle {
						//return ret
						continue
					} else {
						//fmt.Printf("\nroot: %s, item.Value: %s, error: give up depth.", root, item.Value)
						//ret = append(ret, item.Value)
						continue
					}
				}
				v = r.generateSqlite(item.Value, depth-1, rootDepth)
			}
			if v == nil {
				continue
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

func (r *RSG) generate(root string, dbmsName string, depth int, rootDepth int) []string {

	r.curChosenExpr = make(map[*yacc.ExpressionNode]bool)

	if dbmsName == "sqlite" {
		return r.generateSqlite(root, depth, rootDepth)
	} else if dbmsName == "sqlite_bison" {
		return r.generateSqliteBison(root, depth, rootDepth)
	} else if dbmsName == "postgres" {
		return r.generatePostgres(root, depth, rootDepth)
	} else if dbmsName == "cockroachdb" {
		return r.generateCockroach(root, depth, rootDepth)
	} else if dbmsName == "mysql" {
		return r.generateMySQL(root, depth, rootDepth)
	} else {
		panic(fmt.Sprintf("unknown dbms name: %s", dbmsName))
	}
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
