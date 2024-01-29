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

// Helper functions
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
	return r.mapped_keywords
}
