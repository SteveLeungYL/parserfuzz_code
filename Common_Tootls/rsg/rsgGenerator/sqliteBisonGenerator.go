package rsgGenerator

import (
	"fmt"
	"github.com/rsg/yacc"
)

func GenerateSqliteBison(r RSGInterface, root string, depth int, rootDepth int) []string {

	// Initialize to an empty slice instead of nil because nil is the signal
	// that the depth has been exceeded.
	ret := make([]string, 0)
	prods := r.GetAllProds()[root]
	if len(prods) == 0 {
		return []string{r.FormatTokenValue(root)}
	}

	prod := r.MABChooseArm(prods)

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
				v = GenerateSqliteBison(r, item.Value, depth-1, rootDepth)
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
