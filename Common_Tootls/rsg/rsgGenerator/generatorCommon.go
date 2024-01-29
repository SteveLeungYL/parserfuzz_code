package rsgGenerator

import "github.com/rsg/yacc"

// The PathNode is the data structure that used to save
// the whole chosen query path for the RSGInterface generated query.
// The goal of this structure is to be memory efficient and
// simple, and it should be mutable.
type PathNode struct {
	Id        int
	Parent    *PathNode
	ExprProds *yacc.ExpressionNode
	Children  []*PathNode
	IsFav     bool
	// Debug
	//ParentStr string
}

type RSGInterface interface {
	PrioritizeParserRules(root string, parentHash uint32, depth int) []*yacc.ExpressionNode
	MABChooseArm(prods []*yacc.ExpressionNode) *yacc.ExpressionNode
	MarkEdgeCov(prevHash uint32, curHash uint32)
	CheckIsFav(root string, parentHash uint32) bool
	IsInCompProds(root string, curChosenRule *yacc.ExpressionNode) bool

	Intn(n int) int
	Float64() float64
	GetAllProds() map[string][]*yacc.ExpressionNode
	GetPathId() int
	SetPathId(in int)

	FormatTokenValue(in string) string
	GetMappedKeywords() map[string]interface{}
}
