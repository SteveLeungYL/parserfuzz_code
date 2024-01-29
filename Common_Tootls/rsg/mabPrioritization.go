package main

import "github.com/rsg/yacc"

func (r *RSG) MABChooseArm(prods []*yacc.ExpressionNode) *yacc.ExpressionNode {

	resIdx := 0
	//fmt.Printf("\n\n\nori_prods size: %d\n\n\n", len(ori_prods))

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
		//fmt.Printf("\n\n\nUsing resIdx: %d \n\n\n", resIdx)
	}

	//fmt.Printf("\n\n\nori_prods size: %d\n\n\n", len(ori_prods))
	//fmt.Printf("\n\n\nFrom root: %s, Chossing resProd: %v. \n\n\n", root, allProds[resIdx].Items)
	return prods[resIdx]
}
