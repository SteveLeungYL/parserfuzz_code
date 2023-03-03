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
	"math"
	"math/rand"
	"strings"

	"github.com/rsg/yacc"
)

// RSG is a random syntax generator.
type RSG struct {
	Rnd *rand.Rand

	seen  map[string]bool
	prods map[string][]*yacc.ExpressionNode
}

// NewRSG creates a random syntax generator from the given random seed and
// yacc file.
func NewRSG(seed int64, y string, dbmsName string, allowDuplicates bool) (*RSG, error) {
	tree, err := yacc.Parse("sql", y, dbmsName)
	if err != nil {
		fmt.Printf("\nGetting error: %v\n\n", err)
		return nil, err
	}
	rsg := RSG{
		Rnd:   rand.New(&lockedSource{src: rand.NewSource(seed).(rand.Source64)}),
		prods: make(map[string][]*yacc.ExpressionNode),
	}
	if !allowDuplicates {
		rsg.seen = make(map[string]bool)
	}
	for _, prod := range tree.Productions {
		fmt.Printf("For name: %s, getting expressions: %s", prod.Name, prod.Expressions)
		rsg.prods[prod.Name] = prod.Expressions
	}
	return &rsg, nil
}

// Generate generates a unique random syntax from the root node. At most depth
// levels of token expansion are performed. An empty string is returned on
// error or if depth is exceeded. Generate is safe to call from multiple
// goroutines. If Generate is called more times than it can generate unique
// output, it will block forever.
func (r *RSG) Generate(root string, depth int) string {
	for i := 0; i < 100000; i++ {
		s := strings.Join(r.generate(root, depth, depth), " ")
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

func (r *RSG) generate(root string, depth int, rootDepth int) []string {
	// Initialize to an empty slice instead of nil because nil is the signal
	// that the depth has been exceeded.
	ret := make([]string, 0)
	prods := r.prods[root]
	if len(prods) == 0 {
		return []string{r.formatTokenValue(root)}
	}

	prod := prods[r.Intn(len(prods))]

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
					v = r.generate(item.Value, depth-1, rootDepth)
				} else if depth > 0 {
					v = r.generate("SCONST", depth-1, rootDepth)
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
				v = r.generate(item.Value, depth-1, rootDepth)
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
