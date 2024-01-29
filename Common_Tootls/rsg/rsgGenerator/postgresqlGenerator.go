package rsgGenerator

import (
	"fmt"
	"github.com/rsg/yacc"
)

func GeneratePostgres(r RSGInterface, root string, depth int, rootDepth int) []string {

	// Initialize to an empty slice instead of nil because nil is the signal
	// that the depth has been exceeded.
	ret := make([]string, 0)
	prods := r.GetAllProds()[root]
	if len(prods) == 0 {
		return []string{r.FormatTokenValue(root)}
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
					v = GeneratePostgres(r, item.Value, depth-1, rootDepth)
				} else if depth > 0 {
					v = GeneratePostgres(r, "SCONST", depth-1, rootDepth)
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
				v = GeneratePostgres(r, item.Value, depth-1, rootDepth)
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
