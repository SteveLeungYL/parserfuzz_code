package main

import "github.com/rsg/edgeClassifier"

func (r *RSG) ClassifyEdges(dbmsName string) {
	// Construct the terminating or nested Productions (Grammar Edges)

	// Set up the Complicated Node classification function.
	var isCompNode func(rootName string, nodeValue string) bool
	if dbmsName == "sqlite" {
		isCompNode = edgeClassifier.IsSqliteCompNode
	} else if dbmsName == "mysql" {
		isCompNode = edgeClassifier.IsMySQLCompNode
	} else if dbmsName == "mysqlSquirrel" {
		isCompNode = edgeClassifier.IsMySQLSquirrelCompNode
	} else if dbmsName == "cockroachdb" {
		isCompNode = edgeClassifier.IsCockroachDBCompNode
	} else if dbmsName == "tidb" {
		isCompNode = edgeClassifier.IsTiDBCompNode
	} else if dbmsName == "duckdb" {
		isCompNode = edgeClassifier.IsDuckDBCompNode
	} else {
		// Default placeholder.
		isCompNode = func(_ string, in string) bool {
			return false
		}
	}

	for rootName, rootProds := range r.allProds {

		for _, prod := range rootProds {
			// For each single rule.

			// whether the node lead to terminating tokens.
			// assume yes, if encountering non-terminating tokens,
			// change to false.
			isTerm := true
			// whether the node lead to complex nested node.
			// if found, switch to yes.
			isComp := false

			for _, curNode := range prod.Items {
				if isComp {
					// If the current path is already
					// classified as complicated rule
					// Do not continue
					break
				}
				if isCompNode(rootName, curNode.Value) {
					// If the current child node is a complicated node,
					// do not continue the search. This is a complicated node.
					isComp = true
					isTerm = false
					break
				}

				if curNode.Value == rootName || isCompNode(rootName, curNode.Value) {
					// This is a nested rule.
					isComp = true
					isTerm = false
					break
				}

				// See whether the current child node is terminating token.
				childProds, ok := r.allProds[curNode.Value]

				if ok && len(childProds) != 0 {
					// this is not a terminating child node.
					// search one more level.
					// Thoroughly go through all the possible
					// choices from the sub-node.

					// If all children have complicated nodes, treat the current as comp
					isAllGrandChildComp := true
					for _, childProd := range childProds {
						grandChildComp := false
						//if !isTerm {
						//	// If the current path is already
						//	// classified as non-term
						//	// Do not continue
						//	break
						//}
						for _, childNode := range childProd.Items {
							//if !isTerm {
							//	// If the current path is already
							//	// classified as non-term
							//	// Do not continue
							//	break
							//}
							if isCompNode(curNode.Value, childNode.Value) {
								// The grandchildren contains complicated nodes.
								grandChildComp = true
							}
							_, childOk := r.allProds[childNode.Value]
							if childOk {
								// Find the nested child node.
								// Not a terminating node.
								// Do not continue
								isTerm = false
							}
						}
						if !grandChildComp {
							// In on the of the child,
							// Not all grand child contains complicated nodes.
							// The current choice of the subnode should be normal or term.
							isAllGrandChildComp = false
						}
					}

					if isAllGrandChildComp {
						isComp = true
						isTerm = false
					}
				} // finished searching the one child node.
				if isComp {
					break
				}
			} // finished searching all the child node.
			if isTerm {
				prod.NodeComp = 0
				r.allTermProds[rootName] = append(r.allTermProds[rootName], prod)
				//fmt.Printf("\n\n\nDEBUG: Getting terminating root: %s, prod: %v\n\n\n", rootName, prod.Items)
			} else if isComp {
				prod.NodeComp = 2
				r.allCompProds[rootName] = append(r.allCompProds[rootName], prod)
				//fmt.Printf("\n\n\nDEBUG: Getting Complex root: %s, prod: %v\n\n\n", rootName, prod.Items)
			} else {
				prod.NodeComp = 1
				r.allNormProds[rootName] = append(r.allNormProds[rootName], prod)
				//fmt.Printf("\n\n\nDEBUG: Getting Normal root: %s, prod: %v\n\n\n", rootName, prod.Items)
			}
		} // loop: Each single rule.
	} // loop: All rule in one token.

	// For special case, if no termProds, normProds possible.
	// prefer non-recursive rule to recursive rule.
	/*
		values ::= VALUES LP nexprlist RP.  --prefer this one. send to normProds.
		values ::= values COMMA LP nexprlist RP. -- recursive, send to compProds.
		... no other values rules.
	*/
	for rootName, rootProds := range r.allProds {
		// all rules.
		for _, prod := range rootProds {
			// For each single rule.
			isRecursive := false
			for _, curNode := range prod.Items {
				// For each child keyword.
				if rootName == curNode.Value {
					isRecursive = true
					break
				}
			}
			if isRecursive {
				r.allCompRecursiveProds[rootName] = append(r.allCompRecursiveProds[rootName], prod)
			} else {
				//fmt.Printf("\n\n\nSaving root: %s to non-recursive: %v\n\n\n", rootName, prod.Items)
				r.allCompNonRecursiveProds[rootName] = append(r.allCompNonRecursiveProds[rootName], prod)
			}
		}
	}

	if dbmsName == "mysql" {
		// Special handling for the SELECT statement.
		r.allNormProds["query_primary"] = append(r.allNormProds["query_primary"], r.allCompNonRecursiveProds["query_primary"]...)
		r.allCompProds["query_primary"] = append(r.allCompProds["query_primary"], r.allCompNonRecursiveProds["query_primary"]...)
	} else if dbmsName == "cockroachdb" {
		edgeClassifier.RemoveCockroachDBUnimplementedRule(r.allProds)
		edgeClassifier.RemoveCockroachDBUnimplementedRule(r.allTermProds)
		edgeClassifier.RemoveCockroachDBUnimplementedRule(r.allNormProds)
		edgeClassifier.RemoveCockroachDBUnimplementedRule(r.allCompProds)
		edgeClassifier.RemoveCockroachDBUnimplementedRule(r.allCompNonRecursiveProds)
		edgeClassifier.RemoveCockroachDBUnimplementedRule(r.allCompRecursiveProds)
	} else if dbmsName == "tidb" {
		edgeClassifier.RemoveTiDBUnimplementedRule(r.allProds)
		edgeClassifier.RemoveTiDBUnimplementedRule(r.allTermProds)
		edgeClassifier.RemoveTiDBUnimplementedRule(r.allNormProds)
		edgeClassifier.RemoveTiDBUnimplementedRule(r.allCompProds)
		edgeClassifier.RemoveTiDBUnimplementedRule(r.allCompNonRecursiveProds)
		edgeClassifier.RemoveTiDBUnimplementedRule(r.allCompRecursiveProds)
	} else if dbmsName == "duckdb" {
		edgeClassifier.RemoveDuckDBKeywordPlaceholder(r.allProds)
		edgeClassifier.RemoveDuckDBKeywordPlaceholder(r.allTermProds)
		edgeClassifier.RemoveDuckDBKeywordPlaceholder(r.allNormProds)
		edgeClassifier.RemoveDuckDBKeywordPlaceholder(r.allCompProds)
		edgeClassifier.RemoveDuckDBKeywordPlaceholder(r.allCompNonRecursiveProds)
		edgeClassifier.RemoveDuckDBKeywordPlaceholder(r.allCompRecursiveProds)

		edgeClassifier.FindTuningDuckDBRules(r.allProds)
		edgeClassifier.FindTuningDuckDBRules(r.allTermProds)
		edgeClassifier.FindTuningDuckDBRules(r.allNormProds)
		edgeClassifier.FindTuningDuckDBRules(r.allCompProds)
		edgeClassifier.FindTuningDuckDBRules(r.allCompNonRecursiveProds)
		edgeClassifier.FindTuningDuckDBRules(r.allCompRecursiveProds)
	}

	//fmt.Print("All terminating prods: ")
	//fmt.Print(r.allCompProds)

}
