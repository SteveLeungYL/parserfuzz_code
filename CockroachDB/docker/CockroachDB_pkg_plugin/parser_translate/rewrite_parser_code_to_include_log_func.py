import sys
import os

if len(sys.argv) != 2 or "parse.go" not in sys.argv[1]:
    print("Fatal Error: the parsed in file is not parse.go. \n\n\n")
    exit(1)

fd = open(sys.argv[1], "r")

res_str = ""
for cur_line in fd.read().splitlines():
    if "func init()" in cur_line:
        res_str += """

type GramCovLogger struct {
	newUnsavedCov []string
}

var gramCov GramCovLogger

func LogGrammarCoverage(ruleStr string) {
	gramCov.newUnsavedCov = append(gramCov.newUnsavedCov, ruleStr)
}

"""
        res_str += cur_line
        continue
    elif "func Parse(sql string) (Statements, error)" in cur_line:
        res_str += """

func ParseWithCov(sql string) (Statements, error, []string) {
	stmt, err := Parse(sql)
	var newCov = make([]string, len(gramCov.newUnsavedCov))
	copy(newCov, gramCov.newUnsavedCov)
	gramCov.newUnsavedCov = make([]string, 0)
	return stmt, err, newCov
}

"""
        res_str += cur_line
        continue
    else:
        res_str += cur_line + "\n"
	
fd.close()

fd = open(sys.argv[1], "w")
fd.write(res_str)
fd.close()

os.system(f"gofmt -w {sys.argv[1]}")