package globalcov

import (
	"encoding/binary"
	"os"

	//"fmt"
	"log"
	"sync/atomic"
)

var GCov GlobalCovInfo
var sqlrightCh = make(chan uint32, 100)
var controlCh = make(chan uint32)
var isCovRoutineReady int32 = 0

type GlobalCovInfo struct {
	// Default PrevLoc value is 0.
	prevLoc uint32         // Max: 262143
	buf     [1 << 18]uint8 // trace_bit buffer. 262144 size.
}

func InitCovRoutine() {

	// Sub-go-routine for the logging jobs. May save some CPU time
	// for the main routine.
	go func() {
		var x uint32 = 0
		for {
			select {
			case x = <-sqlrightCh:
				// Actual branch coverage logging.
				LogGlobalCov(x)
			case x = <-controlCh:
				if x == 0 {
					// Plot the coverage output.
					SaveGlobalCov()
					controlCh <- 0
					return
				} else if x == 1 {
					// Reset the global coverage.
					ResetGlobalCov()
					controlCh <- 1
				}
			}
		}
	}()

	controlCh <- 1
	<-controlCh

	atomic.StoreInt32(&isCovRoutineReady, 1)

	return
}

func LogCovRoutine(curLoc uint32) {
	if uint8(atomic.LoadInt32(&isCovRoutineReady)) == 1 {
		sqlrightCh <- curLoc
	}
	return
}

func CloseCovRoutine() {

	atomic.StoreInt32(&isCovRoutineReady, 0)

	controlCh <- 0
	<-controlCh
}

func LogGlobalCov(curLoc uint32) {

	offset := getXorOffset(curLoc)

	////Debugging purpose
	//if offset < 66000 && offset > 65000 {
	//log.Printf("\n\n\nDEBUG: Triggered offset: %d, curLoc: %d, prevLoc: %d\n\n\n", offset, curLoc, logPrevLoc)
	//}

	if offset >= (1 << 18) {
		log.Fatalf("Error: Getting oversized offset: %d. \n\n\n", offset)
	}

	// Prevent overflow.
	if GCov.buf[offset] != 255 {
		GCov.buf[offset] += 1
	}
}

func ResetGlobalCov() {
	// Set all buffer to 0.
	for offset := 0; offset < (1 << 18); offset++ {
		GCov.buf[offset] = 0
	}
}

func getXorOffset(curLoc uint32) uint32 {
	// Get the offset result
	res := GCov.prevLoc ^ curLoc
	// Save the right-shifted curLoc
	GCov.prevLoc = (curLoc >> 1)
	return res
}

func SaveGlobalCov() {
	// Plot the coverage output.
	log.Printf("Inside SaveGlobalCov function. ")

	covFile, covOutErr := os.Create("./cov_out.bin")
	if covOutErr != nil {
		panic(covOutErr)
	}
	defer covFile.Close()

	binary.Write(covFile, binary.LittleEndian, GCov.buf)
}
