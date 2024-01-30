package main

import "github.com/rsg/yacc"

func (r *RSG) PrioritizeParserRules(root string, parentHash uint32, depth int) []*yacc.ExpressionNode {

	rootAllRules := r.allProds[root]

	if depth >= 0 && r.fuzzingMode == fuzzingModeNormal && r.Rnd.Intn(2) != 0 {
		// If the current root contains unseen rules, 50% chance, prioritize these unseen rule first.
		// The prioritization is based on all rules possible if depth > 1. Regardless of rootCompProds or not.
		trimRootProds := []*yacc.ExpressionNode{}
		for _, curRule := range rootAllRules {
			if r.CheckEdgeCov(parentHash, curRule.UniqueHash) {
				// Seen rule.
				//fmt.Printf("\n\n\nDebug: root: %s, find seen rule: %v\n\n\n", root, curRule.Items)
			} else {
				// Unseen rule.
				//fmt.Printf("\n\n\nDebug: root: %s, find unseen rule: %v\n\n\n", root, curRule.Items)
				trimRootProds = append(trimRootProds, curRule)
			}
		}

		// If depth > 0 and current root contains unseen rules, return unseen rule directly.
		if len(trimRootProds) != 0 {
			return trimRootProds
		}
	}

	// Otherwise, we prioritize rules based on the complexity of the rules.
	// See whether the depth reached, choose different rule respectively.
	var resRules []*yacc.ExpressionNode
	var ok bool
	if depth <= 0 && r.fuzzingMode < fuzzingModeNoFavNoMABNoCat && r.Rnd.Intn(100) < 95 {
		// Depth IS reached. Prefer simple/term rules than complex rules.
		resRules, ok = r.allTermProds[root]
		//fmt.Printf("\n\n\nUsing Term rules. \n\n\n", root)
		if !ok || len(resRules) == 0 {
			// fallback to the original non-term tokens
			//fmt.Printf("\n\n\nDebug: For root: %s, cannot find any terminating rules. \n\n\n", root)
			resRules, ok = r.allNormProds[root]
			if !ok || len(resRules) == 0 {
				//fmt.Printf("\n\n\nDebug: For root: %s, cannot find any normal rules. \n\n\n", root)
				resRules, ok = r.allCompNonRecursiveProds[root]
				if !ok || len(resRules) == 0 {
					resRules, ok = r.allProds[root]
				}
			}
		}
	} else {
		// Depth IS NOT reached. (or rare escape 5%)
		if r.Rnd.Intn(100) < 30 {
			// 30% chances, prefer comp to norm to term.
			resRules, ok = r.allCompProds[root]
			if !ok || len(resRules) == 0 {
				// fallback to the original non-term tokens
				//fmt.Printf("\n\n\nDebug: For root: %s, cannot find any terminating rules. \n\n\n", root)
				resRules, ok = r.allNormProds[root]
				if !ok || len(resRules) == 0 {
					resRules = r.allProds[root]
				}
			}
		} else {
			// Depth IS NOT reached.
			// 70% chances, use complete all rules possible.
			// It is OK to trigger complex rules here.
			// Complete rely on MABChooseARM to decide from all rules.
			resRules = rootAllRules
		}
	}

	return resRules

}
