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
	"os"
	"strings"
	"sync"
)

func (r *RSG) ClearChosenExpr() {
	// clear the map
	r.curChosenPath = []*rsgGenerator.PathNode{}
	r.pathId = 0
}

func (r *RSG) IncrementSucceed() {

	isFavPath := false
	//fmt.Printf("\nSaving r.curChosenPath size: %d", len(r.curChosenPath))
	//if len(r.curChosenPath) != 0 && r.curChosenPath[0].ExprProds != nil {
	//	fmt.Printf("exprNode: %v\n\n\n", r.curChosenPath[0].ExprProds)
	//}

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

		if curPath.IsFav == true {
			isFavPath = true
		}
	}

	// Save the new nodes to the seed.
	if len(r.curChosenPath) != 0 {
		//fmt.Printf("\n\n\nSaving with type: %s\n\n\n", r.curMutatingType)
		var tmpAllSavedPath [][]*rsgGenerator.PathNode
		tmpAnyAllSavedPath, _ := r.allSavedPath.Load(r.curMutatingType)
		if tmpAnyAllSavedPath != nil {
			tmpAllSavedPath = tmpAnyAllSavedPath.([][]*rsgGenerator.PathNode)
		} else {
			tmpAllSavedPath = [][]*rsgGenerator.PathNode{}
		}

		tmpAllSavedPath = append(tmpAllSavedPath, r.curChosenPath)

		r.allSavedPath.Store(r.curMutatingType, tmpAllSavedPath)
		//fmt.Printf("\nallSavedPath size: %d\n", len(tmpAllSavedPath))
	}

	if len(r.curChosenPath) != 0 && isFavPath == true {
		var tmpAllSavedFavPath [][]*rsgGenerator.PathNode
		tmpAnyAllSavedFavPath, _ := r.allSavedFavPath.Load(r.curMutatingType)
		if tmpAnyAllSavedFavPath != nil {
			tmpAllSavedFavPath = tmpAnyAllSavedFavPath.([][]*rsgGenerator.PathNode)
		} else {
			tmpAllSavedFavPath = [][]*rsgGenerator.PathNode{}
		}

		tmpAllSavedFavPath = append(tmpAllSavedFavPath, r.curChosenPath)

		r.allSavedFavPath.Store(r.curMutatingType, tmpAllSavedFavPath)
	}

	r.ClearChosenExpr()

}

func (r *RSG) IncrementFailed() {

	isFavPath := false

	for _, curPath := range r.curChosenPath {
		prod := curPath.ExprProds
		if prod == nil {
			continue
		}
		prod.HitCount++
		prod.RewardScore =
			(float64(prod.HitCount-1)/float64(prod.HitCount))*prod.RewardScore + (1.0/float64(prod.HitCount))*0.0
		//fmt.Printf("For expr: %q, hit_count: %d, score: %d\n", prod.Items, prod.HitCount, prod.RewardScore)
		if curPath.IsFav == true {
			isFavPath = true
		}
	}

	if len(r.curChosenPath) != 0 && isFavPath == true {
		var tmpAllSavedFavPath [][]*rsgGenerator.PathNode
		tmpAnyAllSavedFavPath, _ := r.allSavedFavPath.Load(r.curMutatingType)
		if tmpAnyAllSavedFavPath != nil {
			tmpAllSavedFavPath = tmpAnyAllSavedFavPath.([][]*rsgGenerator.PathNode)
		} else {
			tmpAllSavedFavPath = [][]*rsgGenerator.PathNode{}
		}

		tmpAllSavedFavPath = append(tmpAllSavedFavPath, r.curChosenPath)

		r.allSavedFavPath.Store(r.curMutatingType, tmpAllSavedFavPath)
	}

	r.ClearChosenExpr()
}

func (r *RSG) SaveFav() {

	isFavPath := false

	for _, curPath := range r.curChosenPath {
		prod := curPath.ExprProds
		if prod == nil {
			continue
		}
		if curPath.IsFav == true {
			isFavPath = true
		}
	}

	if len(r.curChosenPath) != 0 && isFavPath == true {
		var tmpAllSavedFavPath [][]*rsgGenerator.PathNode
		tmpAnyAllSavedFavPath, _ := r.allSavedFavPath.Load(r.curMutatingType)
		if tmpAnyAllSavedFavPath != nil {
			tmpAllSavedFavPath = tmpAnyAllSavedFavPath.([][]*rsgGenerator.PathNode)
		} else {
			tmpAllSavedFavPath = [][]*rsgGenerator.PathNode{}
		}

		tmpAllSavedFavPath = append(tmpAllSavedFavPath, r.curChosenPath)

		r.allSavedFavPath.Store(r.curMutatingType, tmpAllSavedFavPath)
	}

	// No need to clear path in this function.
}

func (r *RSG) deepCopyPathNode(srcNode *rsgGenerator.PathNode, destParentNode *rsgGenerator.PathNode) *rsgGenerator.PathNode {

	// Recursive function. May not be optimal
	if srcNode == nil {
		// Return empty
		fmt.Printf("\n\n\nError: In deepCopyPathNode, getting srcNode is nil. \n\n\n")
		os.Exit(1)
	}

	newDestPathNode := &rsgGenerator.PathNode{
		Id:        srcNode.Id,
		Parent:    destParentNode,
		ExprProds: srcNode.ExprProds,
		Children:  []*rsgGenerator.PathNode{},
		IsFav:     srcNode.IsFav,
		//ParentStr: srcNode.ParentStr,
	}

	for _, curChild := range srcNode.Children {
		newDestChild := r.deepCopyPathNode(curChild, newDestPathNode)
		newDestPathNode.Children = append(newDestPathNode.Children, newDestChild)
	}

	return newDestPathNode
}

func (r *RSG) retrieveExistingFavPathNode(root string) []*rsgGenerator.PathNode {

	var targetPath []*rsgGenerator.PathNode

	srcAnySavedFavPath, pathExisted := r.allSavedFavPath.Load(root)
	if srcAnySavedFavPath == nil {
		return targetPath
	}
	srcSavedFavPath := srcAnySavedFavPath.([][]*rsgGenerator.PathNode)

	if !pathExisted || srcSavedFavPath == nil || len(srcSavedFavPath) == 0 {
		// Return empty targetPath.
		return targetPath
	}

	// Retrieve the FIRST element from the FAV, and then remove the current chosen FAV.
	srcPath := srcSavedFavPath[0]

	srcSavedFavPath = srcSavedFavPath[1:]
	r.allSavedFavPath.Store(root, srcSavedFavPath)

	if len(srcPath) == 0 {
		fmt.Printf("\n\n\nERROR: Saved an empty path nodes to the interesting seeds. "+
			"Root: %s"+
			"\n\n\n", root)
	}

	// Deep Copy the source path from root
	targetPathRoot := r.deepCopyPathNode(srcPath[0], nil)

	targetPath = r.GatherAllPathNodes(targetPathRoot)

	if len(targetPath) == 0 {
		fmt.Printf("\n\n\n Error, getting targetPath len == 0 in the retrieveExistingPathNode. \n\n\n")
		os.Exit(1)
	}

	return targetPath
}

func (r *RSG) retrieveExistingPathNode(root string) []*rsgGenerator.PathNode {

	tmpAnySavedPath, pathExisted := r.allSavedPath.Load(root)
	if !pathExisted || tmpAnySavedPath == nil {
		fmt.Printf("Fatal Error. Cannot find the rsgGenerator.PathNode with %s\n\n\n", root)
		os.Exit(1)
	}

	tmpSavedPath := tmpAnySavedPath.([][]*rsgGenerator.PathNode)
	srcPath := tmpSavedPath[r.Rnd.Intn(len(tmpSavedPath))]
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

func (r *RSG) CheckEdgeCov(prevHash uint32, curHash uint32) bool {
	if r.allTriggerEdges[(prevHash>>1)^curHash] != 0 {
		return true
	} else {
		return false
	}
}

func (r *RSG) MarkEdgeCov(prevHash uint32, curHash uint32) {
	if r.allTriggerEdges[(prevHash>>1)^curHash] != 0xff {
		r.allTriggerEdges[(prevHash>>1)^curHash] += 1
	}
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

func (r *RSG) CheckIsFav(root string, parentHash uint32) bool {
	rootProds := r.allProds[root]

	for _, curRule := range rootProds {
		if r.CheckEdgeCov(parentHash, curRule.UniqueHash) {
			//fmt.Printf("\nDebug: Unseen Rule. Root: %s, Rule: %v\n", root, curRule.Items)
			continue
		}
		// has unseen rule.
		return true
	}
	// cannot find unseen rule.
	return false
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
