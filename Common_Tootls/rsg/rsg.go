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
	"fmt"
	"github.com/rsg/yacc"
	"math"
	"math/rand"
	"strings"
	"unicode"
)

// RSG is a random syntax generator.
type RSG struct {
	Rnd *rand.Rand

	seen  map[string]bool
	prods map[string][]*yacc.ExpressionNode

	curChosenExpr map[*yacc.ExpressionNode]bool
	epsilon       float64
}

// NewRSG creates a random syntax generator from the given random seed and
// yacc file.
func NewRSG(seed int64, y string, dbmsName string, allowDuplicates bool, epsilon float64) (*RSG, error) {

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
	if !allowDuplicates {
		rsg.seen = make(map[string]bool)
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

func (r *RSG) IncrementSucceed() {
	for prod := range r.curChosenExpr {
		prod.RewardScore =
			(float64(prod.HitCount-1)/float64(prod.HitCount))*prod.RewardScore + (1.0/float64(prod.HitCount))*1.0
		//fmt.Printf("For expr: %q, hit_count: %d, score: %d\n", prod.Items, prod.HitCount, prod.RewardScore)
	}
	// clear the map
	r.curChosenExpr = make(map[*yacc.ExpressionNode]bool)
}

func (r *RSG) IncrementFailed() {
	for prod := range r.curChosenExpr {
		prod.RewardScore =
			(float64(prod.HitCount-1)/float64(prod.HitCount))*prod.RewardScore + (1.0/float64(prod.HitCount))*0.0
		//fmt.Printf("For expr: %q, hit_count: %d, score: %d\n", prod.Items, prod.HitCount, prod.RewardScore)
	}
	// clear the map
	r.curChosenExpr = make(map[*yacc.ExpressionNode]bool)
}

func (r *RSG) argMax(rewards []float64) int {

	var maxIdx = 0
	var maxReward = 0.0

	for idx, reward := range rewards {
		if reward > maxReward {
			maxReward = reward
			maxIdx = idx
		} else {
			continue
		}
	}

	return maxIdx

}

func (r *RSG) MABChooseArm(prods []*yacc.ExpressionNode) *yacc.ExpressionNode {

	resIdx := 0
	if r.Rnd.Float64() > r.epsilon {
		var rewards []float64
		for _, prod := range prods {
			rewards = append(rewards, prod.RewardScore)
		}
		resIdx = r.argMax(rewards)
	} else {
		// Random choice.
		resIdx = r.Rnd.Intn(len(prods))
	}

	resProd := prods[resIdx]
	resProd.HitCount++

	// Save to curChosenExpr if not seen before.
	_, ok := r.curChosenExpr[resProd]
	if !ok {
		r.curChosenExpr[resProd] = true
	}

	return prods[resIdx]
}

// Generate generates a unique random syntax from the root node. At most depth
// levels of token expansion are performed. An empty string is returned on
// error or if depth is exceeded. Generate is safe to call from multiple
// goroutines. If Generate is called more times than it can generate unique
// output, it will block forever.
func (r *RSG) Generate(root string, dbmsName string, depth int) string {
	for i := 0; i < 100000; i++ {
		s := strings.Join(r.generate(root, dbmsName, depth, depth), " ")
		if r.seen != nil {
			if !r.seen[s] {
				r.seen[s] = true
			} else {
				s = ""
			}
		}
		if s != "" {
			s = strings.Replace(s, "_LA", "", -1)
			s = strings.Replace(s, " AS OF SYSTEM TIME \"string\"", "", -1)
			return s
		}
	}
	panic("couldn't find unique string")
}

func (r *RSG) generateMySQL(root string, depth int, rootDepth int) []string {
	// Initialize to an empty slice instead of nil because nil is the signal
	// that the depth has been exceeded.
	ret := make([]string, 0)
	prods := r.prods[root]
	if len(prods) == 0 {
		return []string{r.formatTokenValue(root)}
	}

	prod := r.MABChooseArm(prods)

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

	prod := r.MABChooseArm(prods)

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

func (r *RSG) generateSqlite(root string, depth int, rootDepth int) []string {
	// Initialize to an empty slice instead of nil because nil is the signal
	// that the depth has been exceeded.
	ret := make([]string, 0)
	prods := r.prods[root]
	if len(prods) == 0 {
		return []string{r.formatTokenValue(root)}
	}

	prod := r.MABChooseArm(prods)
	//prod := prods[r.Rnd.Intn(len(prods))]

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
				ret = append(ret, " CTIME ")
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
				ret = append(ret, " JOIN ")
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
					return nil
				}
				v = r.generateSqlite(item.Value, depth-1, rootDepth)
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

		tmpProd := r.MABChooseArm(prods)

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
