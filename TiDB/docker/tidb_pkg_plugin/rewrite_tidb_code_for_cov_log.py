import os

db_dir = "/home/tidb/go_projects/src/github.com/tidb/tidb"

# First, handle go.mod
mod_fd = open(os.path.join(db_dir, "go.mod"), "r")
res_str = ""

tmp_is_instr = False
for cur_line in mod_fd.read().splitlines():
    res_str += cur_line + "\n"
    if "require (" in cur_line and tmp_is_instr == False:
        res_str += "github.com/pingcap/tidb/globalcov v0.0.0-20220314125451-bfb5c2c55188\n"
        tmp_is_instr = True
    if "./parser" in cur_line and "replace " in cur_line:
        res_str += "replace github.com/pingcap/tidb/globalcov => ./globalcov\n"
    elif "./parser" in cur_line:
        res_str += "github.com/pingcap/tidb/globalcov => ./globalcov\n"

mod_fd.close()

with open(os.path.join(db_dir, "go.mod"), "w") as mod_fd:
    mod_fd.write(res_str)
res_str = ""

# Second handle the tidb-server/main.go file.
main_fd = open(os.path.join(db_dir, "tidb-server/main.go"), "r")
res_str = ""

tmp_is_instr = False
for cur_line in main_fd.read().splitlines():
    res_str += cur_line + "\n"
    if "import (" in cur_line:
        res_str += '"encoding/binary"\n'
# Append in the end.
res_str += """

var FORKSRV_FD uintptr = 198
var maxQueryExec int = 1000

func TestCov() {

	controlPipe := os.NewFile(FORKSRV_FD, "pipe")
	tmpCtrlRead := []byte{0, 0, 0, 0}
	// Status Write Pipe.
	statusPipe := os.NewFile(FORKSRV_FD+1, "pipe")

	// Forkserver, stop the process right before the query processing.
	// Notify the fuzzer that the server is ready.
	statusPipe.Write([]byte{0, 0, 0, 0})
	statusPipe.Sync()

	go main()

	// Clean up the coverage log.
	globalcov.ResetGlobalCov()
	//defer globalcov.SaveGlobalCov()

	for per_cycle := 0; per_cycle < maxQueryExec; per_cycle++ {

		// Control Read Pipe.
		// Wait for the input signal.
		_, err := controlPipe.Read(tmpCtrlRead)
		if err != nil {
			log.Error("controlPipe reading failed.\\n")
			// Log the code coverage.
			globalcov.SaveGlobalCov()
			return
		}

		tmpCtrlReadInt := binary.LittleEndian.Uint32(tmpCtrlRead)

		if tmpCtrlReadInt == 3 {
			// Log the code coverage.
			globalcov.SaveGlobalCov()
			// Clean up the coverage log.
			globalcov.ResetGlobalCov()

			// Notify the fuzzer that the coverage output has succeeded.
			_, err := statusPipe.Write([]byte{0, 0, 0, 0})
			statusPipe.Sync()
			if err != nil {
				log.Error("StatusPipe writing failed. ")
				return
			}

			continue
		}
	}

	return
}

"""

main_fd.close()

with open(os.path.join(db_dir, "tidb-server/main.go"), "w") as main_fd:
    main_fd.write(res_str)
res_str = ""
os.system(f'gofmt -w {os.path.join(db_dir, "tidb-server/main.go")}')


# At last, handle the main_test.go
main_test_fd = open(os.path.join(db_dir, "tidb-server/main_test.go"), "r")
res_str = ""

skip_line = 0
for cur_line in main_test_fd.read().splitlines():
    if "goleak.VerifyTestMain" in cur_line:
        # ignore goleak
        res_str += "m.Run()\n" # replace the original goleak call to the direct m.Run() call.
        continue
    elif "go.uber.org/goleak" in cur_line:
        continue
    elif "goleak.Option" in cur_line:
        # ignore goleak and the options line.
        skip_line = 4
        continue
    elif "isCoverageServer == \"1\"" in cur_line:
        res_str += "TestCov()\n"
        skip_line = 3
        skip_line -= 1
        continue
    elif skip_line > 0:
        skip_line -= 1
        continue
    res_str += cur_line + "\n"

main_test_fd.close()

with open(os.path.join(db_dir, "tidb-server/main_test.go"), "w") as main_test_fd:
    main_test_fd.write(res_str)
os.system(f'gofmt -w {os.path.join(db_dir, "tidb-server/main_test.go")}')
