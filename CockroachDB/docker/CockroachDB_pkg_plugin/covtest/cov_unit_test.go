package cov_test

import (
	"context"
	"github.com/cockroachdb/cockroach/pkg/sql/tests"
	"github.com/cockroachdb/cockroach/pkg/testutils/serverutils"
	"github.com/cockroachdb/cockroach/pkg/testutils/sqlutils"
	"log"
	"os"
	"strings"
	"testing"
    "fmt"
)

var FORKSRV_FD = 198

var cleanupQuery = `
DROP SCHEDULES WITH x AS (SHOW SCHEDULES) SELECT id FROM x WHERE label = 'schedule_database';
DROP DATABASE WITH x AS (SHOW DATABASES) SELECT id FROM x WHERE database_name != 'system';
`

// Execute the query string, return the results as string.
func executeQuery(sqlStr string, sqlRun *SQLRunner) string {

    // Separate the input queries. If single query fails,
    // the query sequence execution can still continue.
    testingQueryArray := strings.Split(string(sqlStr), "\n")
    resStr := ""

    for idx, testingQuery := range testingQueryArray {

        log.Printf("\n\nDebug: Running on statement %d: %s", idx, testingQuery)
        //out_file.WriteString(fmt.Sprintf("Res IDX: %d\n", idx))

        // Higher lever query running: resRows := sqlRun.Query(t, testingQuery)

        // QueryContext is the most fundamental function to execute one query
        // and returns results. If error happens, this function would only
        // return the error rather than throw a Fatal Error.
        resRows, err := sqlRun.DB.QueryContext(context.Background(), testingQuery)

        if err != nil {
            resStr += fmt.Sprintf("%s\n", err)
        } else {
            tmpR, err := sqlutils.RowsToStrMatrix(resRows)

            if err != nil {
                // TODO: Fix it later.
                // Seems should not happen. 
            } else {
                r := sqlutils.MatrixToStr(tmpR)
                resStr += fmt.Sprintf("%s", r)
            }
        }
    }        

    return resStr

}

func TestCov(t *testing.T) {

    // The Server startup params can be reused multiple times. 
	params, _ := tests.CreateTestServerParams()

    // Setup the server testing env. 
    s, sqlDB, _ := serverutils.StartServer(t, params)
    defer s.Stopper().Stop(context.Background())

    sqlRun := sqlutils.MakeSQLRunner(sqlDB)

    // Control Read Pipe. 
    controlPipe := os.NewFile(FORKSRV_FD, "pipe")
    tmpCtrlRead := []byte{0, 0, 0, 0}
    // Status Write Pipe. 
    statusPipe := os.NewFile(FORKSRV_FD+1, "pipe")

    // Forkserver, stop the process right before the query processing. 
    // Notify the fuzzer that the server is ready. 
    _, err := statusPipe.Write([]byte{0, 0, 0, 0})

    log.Printf("Debug: Inside the coverage unit test. \n")

    for per_cycle := 0; per_cycle < 1000; per_cycle++ {

        // Wait for the input signal. 
        controlPipe.Read(tmpCtrlRead)

        // Reset the database. 
        executeQuery(cleanupQuery, sqlRun)

        // Read query from local file.
        inRaw, err := os.ReadFile("./input_query.sql")
        if err != nil {
            t.Fatal("input_query.sql not existed. ")
        }

        outFile, out_err := os.Create("./query_res_out.txt")
        if out_err != nil {
            panic(out_err)
        }

        // Clean up the coverage log. 
        globalcov.ResetGlobalCov()

        // Execute the query
        queryRes := execute(string(inRaw), sqlRun)
        outFile.WriteString(queryRes)

        outFile.close()

        // Plot the coverage output. 
        globalcov.SaveGlobalCov()

        if per_cycle != 999 {
            // Notify the fuzzer that the execution has succeed. 
            _, err := statusPipe.Write([]byte{0, 0, 0, 0})
        }
    }

    // Notify the fuzzer that the execution has succeed, and the CockroachDB needs rerun. 
    _, err := statusPipe.Write([]byte{1, 0, 0, 0})

    statusPipe.close()


}
