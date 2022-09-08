# A Unit Test Package Plugin for `CockroachDB`. 

To use whole program coverage instrumentation for `CockroachDB`, the built-in `go build` command won't work. It doesn't support the `-cover` flag which were enabled for the `go test` command. Therefore, the current built-in coverage instrumentation only works for `go test` scenarios. 

The new Unit Test Package plugin takes one SQL query file as input, parses the query, runs the query and at last returns the query results as output. Since the Unit Test already goes through all of the query process steps inside the `CockroachDB` application, it can be used to measure the coverage feedback information for all the query processing inside `CockroachDB`. 

## Installation Steps:

1. Compile the whole `CockroachDB` program first. 

```bash
# The latest version of cockroachdb seems to deprecate the Makefile. But tested with `v21.2.15` works fine. 
make build
```

2. Place the current `cov_test` folder inside the `CockroachDB` source file directory: `<cockroachdb_root>/pkg`. 

3. Compile the `Unit Test Only Binary`:

```bash
go test -c -cover -mod=vendor -tags ' gss make x86_64_linux_gnu crdb_test' -ldflags '-X github.com/cockroachdb/cockroach/pkg/build.typ=development -extldflags "" -X "github.com/cockroachdb/cockroach/pkg/build.tag=v21.2.15-dirty" -X "github.com/cockroachdb/cockroach/pkg/build.rev=2326e63d4a9ad62b19056f90f938a00482cbf56a" -X "github.com/cockroachdb/cockroach/pkg/build.cgoTargetTriple=x86_64-linux-gnu"  ' -run "."  -timeout 45m -c -coverpkg=./... ./pkg/cov_test
```

After the command, a binary named `cov_test.test` should be presented in the current working directory. 

4. Create the input query file, named `input_query.sql`.

5. Run the unit test with command: 

```bash
./cov_test.test -test.coverprofile=./cov.txt
```

6. The coverage results should be output to local directory: `cov.txt`. And a copy of the results output is in `res_out.txt`. 
