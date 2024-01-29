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
	"github.com/rsg/rsgGenerator"
	"github.com/rsg/yacc"
	"math/rand"
	"strings"
	"sync"
)

// RSG is a random syntax generator.
type RSG struct {
	Rnd *rand.Rand
	mu  sync.Mutex

	allProds                 map[string][]*yacc.ExpressionNode
	allTermProds             map[string][]*yacc.ExpressionNode // allProds that lead to token termination
	allNormProds             map[string][]*yacc.ExpressionNode // allProds that cannot be defined.
	allCompProds             map[string][]*yacc.ExpressionNode // allProds that doomed to lead to complex expressions.
	allCompRecursiveProds    map[string][]*yacc.ExpressionNode // allProds that doomed to lead to complex expressions.
	allCompNonRecursiveProds map[string][]*yacc.ExpressionNode // allProds that doomed to lead to complex expressions.

	mapped_keywords map[string]interface{}

	curChosenPath   []*rsgGenerator.PathNode
	allSavedPath    sync.Map
	allSavedFavPath sync.Map
	curMutatingType string
	epsilon         float64
	pathId          int
	allTriggerEdges []uint8
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
		Rnd:                      rand.New(&lockedSource{src: rand.NewSource(seed).(rand.Source64)}),
		allProds:                 make(map[string][]*yacc.ExpressionNode), // Used to save all the grammar edges
		allTermProds:             make(map[string][]*yacc.ExpressionNode), // Used to save only the terminating edges
		allNormProds:             make(map[string][]*yacc.ExpressionNode), // Used to save only the unknown complexity edges
		allCompProds:             make(map[string][]*yacc.ExpressionNode), // Used to save only the known complex edges
		allCompRecursiveProds:    make(map[string][]*yacc.ExpressionNode), // Used to save only the known complex edges
		allCompNonRecursiveProds: make(map[string][]*yacc.ExpressionNode), // Used to save only the known complex edges
		curChosenPath:            []*rsgGenerator.PathNode{},
		//allSavedPath:             sync.Map, // no need to init
		//allSavedFavPath:          sync.Map, // no need to init
		epsilon:         epsilon,
		allTriggerEdges: make([]uint8, 65536),
	}

	// Construct all the possible Productions (Grammar Edges)
	for _, prod := range tree.Productions {
		_, ok := rsg.allProds[prod.Name]
		if ok {
			for _, curExpr := range prod.Expressions {
				curExpr.UniqueHash = uint32(rsg.Rnd.Intn(65536)) // setup the unique hash
				rsg.allProds[prod.Name] = append(rsg.allProds[prod.Name], curExpr)
			}
		} else {
			rsg.allProds[prod.Name] = prod.Expressions
		}
	}

	rsg.ClassifyEdges(dbmsName)

	return &rsg, nil
}

// Generate generates a unique random syntax from the root node. At most depth
// levels of token expansion are performed. An empty string is returned on
// error or if depth is exceeded. Generate is safe to call from multiple
// goroutines. If Generate is called more times than it can generate unique
// output, it will block forever.
func (r *RSG) Generate(root string, dbmsName string, depth int) string {
	var s = ""
	// Check whether there are keyword mapping initialization necessary.
	if dbmsName == "tidb" && len(r.mapped_keywords) == 0 {
		r.mapped_keywords = rsgGenerator.MapTidbKeywords()
	}

	// Mark the current mutating types
	// The successfully generated and executed queries would be saved
	// based on the root type.
	r.curMutatingType = strings.Clone(root)
	for i := 0; i < 1000; i++ {
		s = strings.Join(r.generate(root, dbmsName, depth, depth), " ")
		//fmt.Printf("\n\n\nFrom root, %s, depth: %d, getting stmt: %s\n\n\n", root, depth, s)

		if s != "" {
			s = strings.Replace(s, "_LA", "", -1)
			s = strings.Replace(s, " AS OF SYSTEM TIME \"string\"", "", -1)
			return s
		} else {
			//fmt.Printf("Error: Getting empty string from RSGInterface.Generate. \n\n\n")
		}
	}
	return s
}

func (r *RSG) generate(root string, dbmsName string, depth int, rootDepth int) []string {

	var rootPathNode *rsgGenerator.PathNode
	tmpSavedPath, codeCovPathExisted := r.allSavedPath.Load(root)

	if codeCovPathExisted &&
		tmpSavedPath != nil &&
		len(tmpSavedPath.([][]*rsgGenerator.PathNode)) > 0 &&
		r.Rnd.Intn(3) != 0 {
		// 2/3 chances.
		// Replaying mode.

		// whether choosing the FAV PATH for grammar edge exploration.
		isUsingFav := false

		// 1/2 chances, use Favorite Node instead of random choosing saved path.
		// Retrieve a deep copied from the existing seed.
		var newPath []*rsgGenerator.PathNode
		if r.Rnd.Intn(2) == 0 {
			//fmt.Printf("\n\n\nDebug: Retrieve FAV PATH NODE from root: %s.\n\n\n", root)
			newPath = r.retrieveExistingFavPathNode(root)
			isUsingFav = true
		}
		if len(newPath) == 0 {
			newPath = r.retrieveExistingPathNode(root)
			isUsingFav = false
		}

		// Choose a random node to mutate.
		// Do not choose the root to mutate
		var mutateNode *rsgGenerator.PathNode
		if len(newPath) <= 2 {
			mutateNode = newPath[0]
		} else {
			if r.Rnd.Intn(2) != 0 || isUsingFav {
				// Choose Fav node.
				var favPath []*rsgGenerator.PathNode
				for _, curPath := range newPath {
					if curPath.IsFav == true {
						favPath = append(favPath, curPath)
					}
				}

				if len(favPath) != 0 {
					mutateNode = favPath[r.Rnd.Intn(len(favPath))]
					//fmt.Printf("\nDebug: (not accurate log) Choosing FAV rule. Root: %s, Rule: %v\n", root, mutateNode.ExprProds.Items)
				} else {
					// Avoid mutating root node.
					mutateNode = newPath[r.Rnd.Intn(len(newPath)-1)+1]
					//if isUsingFav {
					//	fmt.Printf("\nERROR: (not accurate log) FAV PATH SIZE 0. Root: %s, Rule: %v\n", root, mutateNode.ExprProds.Items)
					//}
				}
				//fmt.Printf("For query: %s, fav node: %s, triggered node: %v\n", strings.Join(r.generateSqlite(root, newPath[0], 0, depth, rootDepth), " "), mutateNode.ParentStr, mutateNode.ExprProds.Items)
			} else {
				// Choose any fav/non-fav nodes to mutate.
				// Avoid mutating root node.
				mutateNode = newPath[r.Rnd.Intn(len(newPath)-1)+1]
			}
		}

		// Remove the ExprProds and the Children,
		// so the generate function would be required to
		// randomly generate any nodes.
		// This operation could free some not-used rsgGenerator.PathNode
		// from the newPath.
		//fmt.Printf("\n\n\nDebug: Choosing mutate node: %v\n\n\n", mutateNode.ExprProds)
		mutateNode.ExprProds = nil
		mutateNode.Children = []*rsgGenerator.PathNode{}

		rootPathNode = newPath[0]

	} else {
		// Construct a new statement.
		rootPathNode = &rsgGenerator.PathNode{
			Id:        r.pathId,
			Parent:    nil,
			ExprProds: nil,
			Children:  []*rsgGenerator.PathNode{},
			IsFav:     false,
		}
	}

	var resStr []string

	if dbmsName == "sqlite" {
		resStr = rsgGenerator.GenerateSqlite(r, root, rootPathNode, 0, depth, rootDepth)
	} else if dbmsName == "sqlite_bison" {
		resStr = rsgGenerator.GenerateSqliteBison(r, root, depth, rootDepth)
	} else if dbmsName == "postgres" {
		resStr = rsgGenerator.GeneratePostgres(r, root, depth, rootDepth)
	} else if dbmsName == "cockroachdb" {
		resStr = rsgGenerator.GenerateCockroach(r, root, rootPathNode, 0, depth, rootDepth)
	} else if dbmsName == "mysql" {
		resStr = rsgGenerator.GenerateMySQL(r, root, rootPathNode, 0, depth, rootDepth)
	} else if dbmsName == "mysqlSquirrel" {
		resStr = rsgGenerator.GenerateMySQLSquirrel(r, root, rootPathNode, 0, depth, rootDepth)
	} else if dbmsName == "tidb" {
		resStr = rsgGenerator.GenerateTiDB(r, root, rootPathNode, 0, depth, rootDepth)
	} else if dbmsName == "duckdb" {
		resStr = rsgGenerator.GenerateDuckDB(r, root, rootPathNode, 0, depth, rootDepth)
	} else {
		panic(fmt.Sprintf("unknown dbms name: %s", dbmsName))
	}

	r.curChosenPath = r.GatherAllPathNodes(rootPathNode)

	return resStr
}
