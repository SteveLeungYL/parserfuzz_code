// Copyright 2015 The Cockroach Authors.
//
// Use of this software is governed by the Business Source License
// included in the file licenses/BSL.txt.
//
// As of the Change Date specified in that file, in accordance with
// the Business Source License, use of this software will be governed
// by the Apache License, Version 2.0, included in the file
// licenses/APL.txt.

package tree

import (
	"strings"

	"github.com/cockroachdb/cockroach/pkg/sql/pgwire/pgcode"
	"github.com/cockroachdb/cockroach/pkg/sql/pgwire/pgerror"
	"github.com/cockroachdb/cockroach/pkg/util"
	"github.com/cockroachdb/cockroach/pkg/util/pretty"
	"github.com/cockroachdb/errors"
)

// Explain represents an EXPLAIN statement.
type Explain struct {
	ExplainOptions

	// Statement is the statement being EXPLAINed.
	Statement Statement
}

// ExplainAnalyze represents an EXPLAIN ANALYZE statement.
type ExplainAnalyze struct {
	ExplainOptions

	// Statement is the statement being EXPLAINed.
	Statement Statement
}

// ExplainOptions contains information about the options passed to an EXPLAIN
// statement.
type ExplainOptions struct {
	Mode  ExplainMode
	Flags [numExplainFlags + 1]bool
}

// ExplainMode indicates the mode of the explain. The default is ExplainPlan.
type ExplainMode uint8

const (
	// ExplainPlan shows information about the planNode tree for a query.
	ExplainPlan ExplainMode = 1 + iota

	// ExplainDistSQL shows the physical distsql plan for a query and whether a
	// query would be run in "auto" DISTSQL mode. See sql/explain_distsql.go for
	// details. If the ANALYZE option is included, the plan is also executed and
	// execution statistics are collected and shown in the diagram.
	ExplainDistSQL

	// ExplainOpt shows the optimized relational expression (from the cost-based
	// optimizer).
	ExplainOpt

	// ExplainVec shows the physical vectorized plan for a query and whether a
	// query would be run in "auto" vectorized mode.
	ExplainVec

	// ExplainDebug generates a statement diagnostics bundle; only used with
	// EXPLAIN ANALYZE.
	ExplainDebug

	// ExplainDDL generates a DDL plan diagram for the statement. Not allowed with
	//
	ExplainDDL

	// ExplainGist generates a plan "gist".
	ExplainGist

	numExplainModes = iota
)

var explainModeStrings = [...]string{
	ExplainPlan:    "PLAN",
	ExplainDistSQL: "DISTSQL",
	ExplainOpt:     "OPT",
	ExplainVec:     "VEC",
	ExplainDebug:   "DEBUG",
	ExplainDDL:     "DDL",
	ExplainGist:    "GIST",
}

var explainModeStringMap = func() map[string]ExplainMode {
	m := make(map[string]ExplainMode, numExplainModes)
	for i := ExplainMode(1); i <= numExplainModes; i++ {
		m[explainModeStrings[i]] = i
	}
	return m
}()

func (m ExplainMode) String() string {
	if m == 0 || m > numExplainModes {
		panic(errors.AssertionFailedf("invalid ExplainMode %d", m))
	}
	return explainModeStrings[m]
}

// ExplainFlag is a modifier in an EXPLAIN statement (like VERBOSE).
type ExplainFlag uint8

// Explain flags.
const (
	ExplainFlagVerbose ExplainFlag = 1 + iota
	ExplainFlagTypes
	ExplainFlagEnv
	ExplainFlagCatalog
	ExplainFlagJSON
	ExplainFlagMemo
	ExplainFlagShape
	ExplainFlagViz
	numExplainFlags = iota
)

var explainFlagStrings = [...]string{
	ExplainFlagVerbose: "VERBOSE",
	ExplainFlagTypes:   "TYPES",
	ExplainFlagEnv:     "ENV",
	ExplainFlagCatalog: "CATALOG",
	ExplainFlagJSON:    "JSON",
	ExplainFlagMemo:    "MEMO",
	ExplainFlagShape:   "SHAPE",
	ExplainFlagViz:     "VIZ",
}

var explainFlagStringMap = func() map[string]ExplainFlag {
	m := make(map[string]ExplainFlag, numExplainFlags)
	for i := ExplainFlag(1); i <= numExplainFlags; i++ {
		m[explainFlagStrings[i]] = i
	}
	return m
}()

func (f ExplainFlag) String() string {
	if f == 0 || f > numExplainFlags {
		panic(errors.AssertionFailedf("invalid ExplainFlag %d", f))
	}
	return explainFlagStrings[f]
}

// Format implements the NodeFormatter interface.
func (node *Explain) Format(ctx *FmtCtx) {
	ctx.WriteString("EXPLAIN ")
	b := util.MakeStringListBuilder("(", ", ", ") ")
	if node.Mode != ExplainPlan {
		b.Add(ctx, node.Mode.String())
	}

	for f := ExplainFlag(1); f <= numExplainFlags; f++ {
		if node.Flags[f] {
			b.Add(ctx, f.String())
		}
	}
	b.Finish(ctx)
	ctx.FormatNode(node.Statement)
}

// SQLRight Code Injection.
func (node *Explain) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "EXPLAIN "
	infix := ""
	suffix := ""

	var explainMode *SQLRightIR
	if node.Mode != ExplainPlan {
		explainMode = &SQLRightIR{
			NodeHash: 130692,
			IRType:   TypeExplainMode,
			DataType: DataNone,
			Prefix:   node.Mode.String(),
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		prefix = "EXPLAIN ("
		infix = ", "
		suffix = ")"
	}

	rootIR := &SQLRightIR{
		NodeHash: 3365,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    explainMode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	for f := ExplainFlag(1); f <= numExplainFlags; f++ {
		if node.Flags[f] {
			explainFlagNode := &SQLRightIR{
				NodeHash: 144847,
				IRType:   TypeExplainFlag,
				DataType: DataNone,
				Prefix:   f.String(),
				Infix:    "",
				Suffix:   "",
				Depth:    depth,
			}
			rootIR = &SQLRightIR{
				NodeHash: 43522,
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    explainFlagNode,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}
			prefix = "EXPLAIN ("
			infix = ", "
			suffix = ")"
		}
	}

	rootIR.Prefix = prefix
	rootIR.Suffix = suffix

	statementNode := node.Statement.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		NodeHash: 68838,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    statementNode,
		Prefix:   "",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	rootIR.NodeHash = 51981
	rootIR.IRType = TypeExplain

	return rootIR

}

// doc is part of the docer interface.
func (node *Explain) doc(p *PrettyCfg) pretty.Doc {
	d := pretty.Keyword("EXPLAIN")
	var opts []pretty.Doc
	if node.Mode != ExplainPlan {
		opts = append(opts, pretty.Keyword(node.Mode.String()))
	}
	for f := ExplainFlag(1); f <= numExplainFlags; f++ {
		if node.Flags[f] {
			opts = append(opts, pretty.Keyword(f.String()))
		}
	}
	if len(opts) > 0 {
		d = pretty.ConcatSpace(
			d,
			p.bracket("(", p.commaSeparated(opts...), ")"),
		)
	}
	return p.nestUnder(d, p.Doc(node.Statement))
}

// Format implements the NodeFormatter interface.
func (node *ExplainAnalyze) Format(ctx *FmtCtx) {
	ctx.WriteString("EXPLAIN ANALYZE ")
	b := util.MakeStringListBuilder("(", ", ", ") ")
	if node.Mode != ExplainPlan {
		b.Add(ctx, node.Mode.String())
	}

	for f := ExplainFlag(1); f <= numExplainFlags; f++ {
		if node.Flags[f] {
			b.Add(ctx, f.String())
		}
	}
	b.Finish(ctx)
	ctx.FormatNode(node.Statement)
}

// SQLRight Code Injection.
func (node *ExplainAnalyze) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "EXPLAIN ANALYZE "
	infix := ""
	suffix := ""

	var explainMode *SQLRightIR
	if node.Mode != ExplainPlan {
		explainMode = &SQLRightIR{
			NodeHash: 52129,
			IRType:   TypeExplainMode,
			DataType: DataNone,
			Prefix:   node.Mode.String(),
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		prefix = "EXPLAIN ANALYZE ("
		suffix = ")"
		infix = ", "
	}

	rootIR := &SQLRightIR{
		NodeHash: 245399,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    explainMode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	for f := ExplainFlag(1); f <= numExplainFlags; f++ {
		if node.Flags[f] {
			explainFlagNode := &SQLRightIR{
				NodeHash: 195662,
				IRType:   TypeExplainFlag,
				DataType: DataNone,
				Prefix:   f.String(),
				Infix:    "",
				Suffix:   "",
				Depth:    depth,
			}
			rootIR = &SQLRightIR{
				NodeHash: 195735,
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    explainFlagNode,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}
			infix = ", "
			prefix = "EXPLAIN ANALYZE ("
			suffix = ")"
		}
	}

	rootIR.Prefix = prefix
	rootIR.Suffix = suffix

	statementNode := node.Statement.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		NodeHash: 18903,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    statementNode,
		Prefix:   "",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	rootIR.NodeHash = 24043
	rootIR.IRType = TypeExplainAnalyze

	return rootIR
}

// doc is part of the docer interface.
func (node *ExplainAnalyze) doc(p *PrettyCfg) pretty.Doc {
	d := pretty.Keyword("EXPLAIN ANALYZE")
	var opts []pretty.Doc
	if node.Mode != ExplainPlan {
		opts = append(opts, pretty.Keyword(node.Mode.String()))
	}
	for f := ExplainFlag(1); f <= numExplainFlags; f++ {
		if node.Flags[f] {
			opts = append(opts, pretty.Keyword(f.String()))
		}
	}
	if len(opts) > 0 {
		d = pretty.ConcatSpace(
			d,
			p.bracket("(", p.commaSeparated(opts...), ")"),
		)
	}
	return p.nestUnder(d, p.Doc(node.Statement))
}

// MakeExplain parses the EXPLAIN option strings and generates an Explain
// or ExplainAnalyze statement.
func MakeExplain(options []string, stmt Statement) (Statement, error) {
	for i := range options {
		options[i] = strings.ToUpper(options[i])
	}
	var opts ExplainOptions
	var analyze bool
	for _, opt := range options {
		opt = strings.ToUpper(opt)
		if m, ok := explainModeStringMap[opt]; ok {
			if opts.Mode != 0 {
				return nil, pgerror.Newf(pgcode.Syntax, "cannot set EXPLAIN mode more than once: %s", opt)
			}
			opts.Mode = m
			continue
		}
		if opt == "ANALYZE" {
			analyze = true
			continue
		}
		flag, ok := explainFlagStringMap[opt]
		if !ok {
			return nil, pgerror.Newf(pgcode.Syntax, "unsupported EXPLAIN option: %s", opt)
		}
		opts.Flags[flag] = true
	}
	if opts.Mode == 0 {
		// Default mode is ExplainPlan.
		opts.Mode = ExplainPlan
	}
	if opts.Flags[ExplainFlagJSON] {
		if opts.Mode != ExplainDistSQL {
			return nil, pgerror.Newf(pgcode.Syntax, "the JSON flag can only be used with DISTSQL")
		}
		if analyze {
			return nil, pgerror.Newf(pgcode.Syntax, "the JSON flag cannot be used with ANALYZE")
		}
	}

	if analyze {
		if opts.Mode != ExplainDistSQL && opts.Mode != ExplainDebug && opts.Mode != ExplainPlan {
			return nil, pgerror.Newf(pgcode.Syntax, "EXPLAIN ANALYZE cannot be used with %s", opts.Mode)
		}
		return &ExplainAnalyze{
			ExplainOptions: opts,
			Statement:      stmt,
		}, nil
	}

	if opts.Mode == ExplainDebug {
		return nil, pgerror.Newf(pgcode.Syntax, "DEBUG flag can only be used with EXPLAIN ANALYZE")
	}
	return &Explain{
		ExplainOptions: opts,
		Statement:      stmt,
	}, nil
}
