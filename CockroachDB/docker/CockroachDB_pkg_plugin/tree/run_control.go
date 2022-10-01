// Copyright 2017 The Cockroach Authors.
//
// Use of this software is governed by the Business Source License
// included in the file licenses/BSL.txt.
//
// As of the Change Date specified in that file, in accordance with
// the Business Source License, use of this software will be governed
// by the Apache License, Version 2.0, included in the file
// licenses/APL.txt.

package tree

// ControlJobs represents a PAUSE/RESUME/CANCEL JOBS statement.
type ControlJobs struct {
	Jobs    *Select
	Command JobCommand
	Reason  Expr
}

// JobCommand determines which type of action to effect on the selected job(s).
type JobCommand int

// JobCommand values
const (
	PauseJob JobCommand = iota
	CancelJob
	ResumeJob
)

// JobCommandToStatement translates a job command integer to a statement prefix.
var JobCommandToStatement = map[JobCommand]string{
	PauseJob:  "PAUSE",
	CancelJob: "CANCEL",
	ResumeJob: "RESUME",
}

// Format implements the NodeFormatter interface.
func (n *ControlJobs) Format(ctx *FmtCtx) {
	ctx.WriteString(JobCommandToStatement[n.Command])
	ctx.WriteString(" JOBS ")
	ctx.FormatNode(n.Jobs)
	if n.Reason != nil {
		ctx.WriteString(" WITH REASON = ")
		ctx.FormatNode(n.Reason)
	}
}

// SQLRight Code Injection.
func (node *ControlJobs) LogCurrentNode(depth int) *SQLRightIR {

	prefix := JobCommandToStatement[node.Command]
	prefix += " JOBS "

	jobsNode := node.Jobs.LogCurrentNode(depth + 1)

	infix := ""
	var reasonNode *SQLRightIR
	if node.Reason != nil {
		infix = " WITH REASON = "
		reasonNode = node.Reason.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		IRType:   TypeControlJobs,
		DataType: DataNone,
		LNode:    jobsNode,
		RNode:    reasonNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// CancelQueries represents a CANCEL QUERIES statement.
type CancelQueries struct {
	Queries  *Select
	IfExists bool
}

// Format implements the NodeFormatter interface.
func (node *CancelQueries) Format(ctx *FmtCtx) {
	ctx.WriteString("CANCEL QUERIES ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(node.Queries)
}

// SQLRight Code Injection.
func (node *CancelQueries) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "CANCEL QUERIES "

	optIfExistStr := ""
	if node.IfExists {
		optIfExistStr = "IF EXISTS "
	}
	ifExistsNode := &SQLRightIR{
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	queriesNode := node.Queries.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeCancelQueries,
		DataType: DataNone,
		LNode:    ifExistsNode,
		RNode:    queriesNode,
		Prefix:   prefix,
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// CancelSessions represents a CANCEL SESSIONS statement.
type CancelSessions struct {
	Sessions *Select
	IfExists bool
}

// Format implements the NodeFormatter interface.
func (node *CancelSessions) Format(ctx *FmtCtx) {
	ctx.WriteString("CANCEL SESSIONS ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(node.Sessions)
}

// SQLRight Code Injection.
func (node *CancelSessions) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "CANCEL SESSIONS "

	optIfExistStr := ""
	if node.IfExists {
		optIfExistStr = "IF EXISTS "
	}
	ifExistsNode := &SQLRightIR{
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	queriesNode := node.Sessions.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeCancelSessions,
		DataType: DataNone,
		LNode:    ifExistsNode,
		RNode:    queriesNode,
		Prefix:   prefix,
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ScheduleCommand determines which type of action to effect on the selected job(s).
type ScheduleCommand int

// ScheduleCommand values
const (
	PauseSchedule ScheduleCommand = iota
	ResumeSchedule
	DropSchedule
)

func (c ScheduleCommand) String() string {
	switch c {
	case PauseSchedule:
		return "PAUSE"
	case ResumeSchedule:
		return "RESUME"
	case DropSchedule:
		return "DROP"
	default:
		panic("unhandled schedule command")
	}
}

// ControlSchedules represents PAUSE/RESUME SCHEDULE statement.
type ControlSchedules struct {
	Schedules *Select
	Command   ScheduleCommand
}

var _ Statement = &ControlSchedules{}

// Format implements the NodeFormatter interface.
func (n *ControlSchedules) Format(ctx *FmtCtx) {
	ctx.WriteString(n.Command.String())
	ctx.WriteString(" SCHEDULES ")
	ctx.FormatNode(n.Schedules)
}

// SQLRight Code Injection.
func (node *ControlSchedules) LogCurrentNode(depth int) *SQLRightIR {

	prefix := node.Command.String()
	prefix += " SCHEDULES "

	scheduleNode := node.Schedules.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeControlSchedules,
		DataType: DataNone,
		LNode:    scheduleNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ControlJobsForSchedules represents PAUSE/RESUME/CANCEL clause
// which applies job command to the jobs matching specified schedule(s).
type ControlJobsForSchedules struct {
	Schedules *Select
	Command   JobCommand
}

// ControlJobsOfType represents PAUSE/RESUME/CANCEL clause which
// applies the job command to the job matching a specified type
type ControlJobsOfType struct {
	Type    string
	Command JobCommand
}

// Format implements the NodeFormatter interface.
func (n *ControlJobsOfType) Format(ctx *FmtCtx) {
	ctx.WriteString(JobCommandToStatement[n.Command])
	ctx.WriteString(" ALL ")
	ctx.WriteString(n.Type)
	ctx.WriteString(" JOBS")
}

// SQLRight Code Injection.
func (node *ControlJobsOfType) LogCurrentNode(depth int) *SQLRightIR {

	prefix := JobCommandToStatement[node.Command]
	prefix += " ALL "

	typeNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataTypeName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Type,
	}

	infix := " JOBS"

	rootIR := &SQLRightIR{
		IRType:   TypeControlJobsOfType,
		DataType: DataNone,
		LNode:    typeNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// Format implements NodeFormatter interface.
func (n *ControlJobsForSchedules) Format(ctx *FmtCtx) {
	ctx.WriteString(JobCommandToStatement[n.Command])
	ctx.WriteString(" JOBS FOR SCHEDULES ")
	ctx.FormatNode(n.Schedules)
}

// SQLRight Code Injection.
func (node *ControlJobsForSchedules) LogCurrentNode(depth int) *SQLRightIR {

	prefix := JobCommandToStatement[node.Command]
	prefix += " JOBS FOR SCHEDULES "

	schedulesNode := node.Schedules.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeControlJobsForSchedules,
		DataType: DataNone,
		LNode:    schedulesNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

var _ Statement = &ControlJobsForSchedules{}
var _ Statement = &ControlJobsOfType{}
