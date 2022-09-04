package cov_test

import (
	"context"
	"fmt"
	"github.com/cockroachdb/cockroach/pkg/sql/tests"
	"github.com/cockroachdb/cockroach/pkg/testutils/serverutils"
	"github.com/cockroachdb/cockroach/pkg/testutils/sqlutils"
	"log"
	"os"
	"strings"
	"testing"
)

func TestCov(t *testing.T) {

	params, _ := tests.CreateTestServerParams()
	s, sqlDB, _ := serverutils.StartServer(t, params)
	defer s.Stopper().Stop(context.Background())
	//ctx := context.Background()

	sqlRun := sqlutils.MakeSQLRunner(sqlDB)

	//	testingQuery := `
	//        CREATE DATABASE t;
	//        CREATE TABLE t.kv (k CHAR PRIMARY KEY, v CHAR, FAMILY (k), FAMILY (v));
	//        INSERT INTO t.kv VALUES ('c', 'e'), ('a', 'c'), ('b', 'd');
	//		SELECT * FROM t.kv;
	//`

	log.Printf("Debug: Inside the coverage unit test. \n")

	// Read from local file.
	in_raw, err := os.ReadFile("./input_query.sql")
	if err != nil {
		t.Fatal("input_query.sql not existed. ")
	}

	out_file, out_err := os.Create("./res_out.txt")
	if out_err != nil {
		panic(out_err)
	}
	defer out_file.Close()

	// Separate the input queries. If single query fails,
	// the query sequence execution can still continue.
	testingQueryArray := strings.Split(string(in_raw), "\n")

	for idx, testingQuery := range testingQueryArray {

		log.Printf("\n\nDebug: Running on statement %d: %s", idx, testingQuery)
		out_file.WriteString(fmt.Sprintf("Res IDX: %d\n", idx))

		// Higher lever query running: resRows := sqlRun.Query(t, testingQuery)

		// QueryContext is the most fundamental function to execute one query
		// and returns results. If error happens, this function would only
		// return the error rather than throw a Fatal Error.
		resRows, err := sqlRun.DB.QueryContext(context.Background(), testingQuery)

		if err != nil {
			log.Printf("Debug: Getting Error: %s", err)
			out_file.WriteString(fmt.Sprintf("%s\n", err))
		} else {
			log.Printf("Debug: Before RowstoStr. \n")
			tmpR, err := sqlutils.RowsToStrMatrix(resRows)

			if err != nil {
				log.Printf("Debug: Error getting: %s", err)
			} else {
				r := sqlutils.MatrixToStr(tmpR)
				log.Printf("Debug: Getting results %s", r)

				out_file.WriteString(fmt.Sprintf("%s", r))
			}
		}

		log.Printf("Debug: Current query execution End. ")
	}

}

