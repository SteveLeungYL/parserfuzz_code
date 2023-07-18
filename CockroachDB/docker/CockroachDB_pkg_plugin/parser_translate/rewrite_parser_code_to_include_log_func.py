import sys
import os

if len(sys.argv) != 2 or "lexer.go" not in sys.argv[1]:
    print("Fatal Error: the parsed in file is not parse.go. \n\n\n")
    exit(1)

fd = open(sys.argv[1], "r")

res_str = ""
for cur_line in fd.read().splitlines():
    if '"fmt"' in cur_line:
        res_str += cur_line + "\n"
        res_str += '"os"\n'
        continue
    elif "type lexer struct {" in cur_line:
        res_str += """
type GramCovLogger struct {
	gramCovMap    map[string]int
	newUnsavedCov []string
	outFile       *os.File
}

"""
        res_str += cur_line + "\n"
        res_str += """
    gramCov GramCovLogger
"""
        continue
    elif "l.nakedIntType = nakedIntType" in cur_line:
        res_str += cur_line + "\n"
        res_str += """
	l.gramCov.gramCovMap = make(map[string]int)
	l.gramCov.newUnsavedCov = make([]string, 0)
	l.gramCov.outFile, _ = os.OpenFile("./gram_cov.txt", os.O_WRONLY, 0644)
"""
        continue
    else:
        res_str += cur_line + "\n"
	
res_str += """

func (l *lexer) LogGrammarCoverage(ruleStr string) {
	l.gramCov.newUnsavedCov = append(l.gramCov.newUnsavedCov, ruleStr)
}

func (l *lexer) HasNewGrammarCoverage() {
	for _, ruleStr := range l.gramCov.newUnsavedCov {
		if val, ok := l.gramCov.gramCovMap[ruleStr]; !ok || val != 1 {
			l.gramCov.gramCovMap[ruleStr] = 1
			l.gramCov.outFile.WriteString(ruleStr)
		}
	}

	l.gramCov.newUnsavedCov = make([]string, 0)
}

"""

fd.close()

fd = open(sys.argv[1], "w")
fd.write(res_str)
fd.close()

os.system(f"gofmt -w {sys.argv[1]}")