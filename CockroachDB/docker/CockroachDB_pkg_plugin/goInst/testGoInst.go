package main

import (
	"fmt"
)

func testMain() {
	fmt.Println("testprogram")
	DoStuff()
}

func unexportedFunction() {}

// Whatever does other stuff
func Whatever() {}

func AnExportedFunction() {}

func DoStuff() {}

// DoOtherStuff does other stuff
func DoOtherStuff() {}
