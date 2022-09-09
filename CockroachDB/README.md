# Steps to build a `CockroachDB` database with coverage feedback. 

1. Use the original `Golang` library. Tested with `go 1.16.15`. 
2. Download the `CockroachDB` database, checkout to a specific version. Tested with version `v21.2.15`. 
3. Inside the `CockroachDB` database, run `make build`. Strangely, it is common that we need to call `make build` **multiple times** before we can actually compile the `cockroach` binary. 
4. Once the `cockroach` binary has been compiled, edit the `go.mod` file from the `cockroach` root directory. Add the following lines to the file. 
    - before `require (`, add `replace github.com/globalcov => ../../globalcov`
    - inside `require ()`, add `github.com/globalcov v0.0.0-00010101000000-000000000000`
5. After modifying the `go.mod` file, run `go mod vendor` on the `cockroach` root directory. 
6. Copy the `covtest` folder to the `<cockroach_root>/pkg` folder. 
7. Copy the `inst_script.py` script to the parent folder of the `cockroach` root directory, run the script: `python3 inst_script.py`.
8. Copy the `globalcov` folder to `<cockroach_root/vendor/github.com>`.
9. For unknown reasons, the cockroach go files will search for `github` folder instead of `github.com` folder for the dependencies. Therefore, create the `github` folder in `<cockroach_root>/vendor`, copy `globalcov` inside `<cockroach_root>/vendor/github`. 
10. In an unmodified go library, replace the `cover.go` which is located in `<go_root>/src/cmd/cover/cover.go`. 
11. Run the `buildall.bash` script in `<go_root>/src`. No need to wait for all the process finished. After you see the installation succeed hints, we can terminate the build process. 
12. Replace the system go library `/usr/local/go` with the modified one. 
13. In the cockroach root folder, run the `covtest` compilation command. 

```bash
go test -c -cover -mod=vendor -tags ' gss make x86_64_linux_gnu crdb_test' -ldflags '-X github.com/cockroachdb/cockroach/pkg/build.typ=development -extldflags "" -X "github.com/cockroachdb/cockroach/pkg/build.tag=v21.2.15-dirty" -X "github.com/cockroachdb/cockroach/pkg/build.rev=2326e63d4a9ad62b19056f90f938a00482cbf56a" -X "github.com/cockroachdb/cockroach/pkg/build.cgoTargetTriple=x86_64-linux-gnu"  ' -run "."  -timeout 45m -covermode=set -coverpkg=./... ./pkg/covtest
```

14. The instrumented binary `covtest.test` would be outputted to the cockroach root directory. 
