import sys
import os

if len(sys.argv) != 2 or "parse.go" not in sys.argv[1]:
    print("Fatal Error: the parsed in file is not parse.go. \n\n\n")
    exit(1)

fd = open(sys.argv[1], "r")

res_str = ""
for cur_line in fd.read().splitlines():
    if "go/constant" in cur_line:
        res_str += cur_line + "\n"
        res_str += '"os"\n'
        continue
    elif "func init() {" in cur_line:
        res_str += """
type GramCovLogger struct {
	gram_cov_map    map[string]int
	new_unsaved_cov []string
	out_file        *os.File
}

var gramCov GramCovLogger

func LogGrammarCoverage(ruleStr string) {
	gramCov.new_unsaved_cov = append(gramCov.new_unsaved_cov, ruleStr)
}

func HasNewGrammarCoverage() {
	for _, ruleStr := range gramCov.new_unsaved_cov {
		if val, ok := gramCov.gram_cov_map[ruleStr]; !ok || val != 1 {
			gramCov.gram_cov_map[ruleStr] = 1
			gramCov.out_file.WriteString(ruleStr)
		}
	}

	gramCov.new_unsaved_cov = make([]string, 0)
}

"""
        res_str += cur_line + "\n"
        res_str += """
	gramCov.gram_cov_map = make(map[string]int)
	gramCov.new_unsaved_cov = make([]string, 0)
	gramCov.out_file, _ = os.OpenFile("./gram_cov.txt", os.O_WRONLY, 0644)
"""
        continue
    else:
        res_str += cur_line + "\n"

fd.close()

fd = open(sys.argv[1], "w")
fd.write(res_str)
fd.close()

os.system(f"gofmt -w {sys.argv[1]}")