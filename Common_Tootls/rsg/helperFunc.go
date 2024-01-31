package main

import (
	"encoding/json"
	"fmt"
	"github.com/rsg/rsgGenerator"
	"github.com/rsg/yacc"
	"math"
	"math/rand"
	"os"
	"strings"
)

// Constant Values
type FuzzingMode int

const (
	fuzzingModeNormal               FuzzingMode = 0 // Enable all ParserFuzz features
	fuzzingModeNoFav                FuzzingMode = 1 // Disable unseen rule prioritization
	fuzzingModeNoFavNoMAB           FuzzingMode = 2 // Further disable MAB based rule prioritization
	fuzzingModeNoFavNoMABNoAcc      FuzzingMode = 3 // Further disable Categorization-based rule prioritization
	fuzzingModeNoFavNoMABNoAccNoCat FuzzingMode = 4 // Further disable the accumulative mutations
)

var (
	fuzzingModeMap = map[string]FuzzingMode{
		"normal":               fuzzingModeNormal,
		"noFav":                fuzzingModeNoFav,
		"noFavNoMAB":           fuzzingModeNoFavNoMAB,
		"noFavNoMABNoAcc":      fuzzingModeNoFavNoMABNoAcc,
		"noFavNoMABNoAccNoCat": fuzzingModeNoFavNoMABNoAccNoCat,
	}
)

// Helper functions
func (r *RSG) identifyFuzzingMode(in string) FuzzingMode {

	c, ok := fuzzingModeMap[in]

	if !ok {
		err := fmt.Errorf("Error: Provided with unknown fuzzingMode string: %s ", in)
		fmt.Println(err)
		os.Exit(1)
	}

	return c
}

func (r *RSG) FormatTokenValue(in string) string {

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

func (r *RSG) argMax(rewards []float64) int {

	var maxIdx []int
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

func (r *RSG) DumpParserRuleMap(outFile string) {

	resJsonStr, err := json.Marshal(r.allProds)

	if err != nil {
		fmt.Printf("\n\n\nError: Cannot generate the r.allProds JSON file. \n\n\n")
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

func (r *RSG) DumpEdgeCovMap() {
	fmt.Printf("\n\n\nLogging: Dump edge map: \n%v\n\n\n", r.allTriggerEdges)
}

func (r *RSG) GatherAllPathNodes(curPathNode *rsgGenerator.PathNode) []*rsgGenerator.PathNode {
	// Recursive function. May not be optimal
	var pathArray = []*rsgGenerator.PathNode{}
	if curPathNode == nil {
		// Return empty
		fmt.Printf("\n\n\nError: Getting nil curPathNode from GatherAllPathNodes\n\n\n")
		return pathArray
	}
	pathArray = append(pathArray, curPathNode)
	for _, curChild := range curPathNode.Children {
		childPathArray := r.GatherAllPathNodes(curChild)
		pathArray = append(pathArray, childPathArray...)
	}

	return pathArray
}

func (r *RSG) GetAllProds() map[string][]*yacc.ExpressionNode {
	return r.allProds
}

func (r *RSG) GetAllCompProds() map[string][]*yacc.ExpressionNode {
	return r.allCompProds
}

func (r *RSG) GetPathId() int {
	return r.pathId
}

func (r *RSG) SetPathId(in int) {
	r.pathId = in
}

func (r *RSG) IsInCompProds(root string, curChosenRule *yacc.ExpressionNode) bool {
	isChooseCompRule := false
	// Check whether the chosen rule is complex rule, i.e., select, expr, nexpr etc.
	for _, val := range r.allCompProds[root] {
		if val == curChosenRule {
			//fmt.Printf("\n\n\nDebugging: Complex rule matched: val: %v, curChosenRule: %v\n\n\n", val.Items, curChosenRule.Items)
			isChooseCompRule = true
			break
		}
	}

	return isChooseCompRule
}

func (r *RSG) GetMappedKeywords() map[string]interface{} {
	return r.mappedKeywords
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
