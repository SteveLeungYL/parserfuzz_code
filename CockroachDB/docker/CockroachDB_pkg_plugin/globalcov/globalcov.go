package globalcov

import (
	"encoding/binary"
	"errors"
	"fmt"
	"os"
	"time"
)

var GCov GlobalCovInfo

type GlobalCovInfo struct {
	// Default PrevLoc value is 0.
	prevLoc uint32         // Max: 262143
	buf     [1 << 18]uint8 // trace_bit buffer. 262144 size.
}

func LogGlobalCov(curLoc uint32) {

	offset := getXorOffset(curLoc)
	// offset := curLoc

	////Debugging purpose
	//if offset < 66000 && offset > 65000 {
	//log.Printf("\n\n\nDEBUG: Triggered offset: %d, curLoc: %d, prevLoc: %d\n\n\n", offset, curLoc, logPrevLoc)
	//}

	//	if offset >= (1 << 18) {
	//		log.Fatalf("Error: Getting oversized offset: %d. \n\n\n", offset)
	//	}

	// Prevent overflow.

	// With hit count.
	//	if GCov.buf[offset] != 255 {
	//		GCov.buf[offset] = 1
	//	}

	// Without hit count.
	if GCov.buf[offset] == 0 {
		GCov.buf[offset] = 1
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

func CountNonCov() uint32 {
	var res uint32 = 0
	for _, curCov := range GCov.buf {
		if curCov != 0 {
			res += 1
		}
	}
	return res
}

func SaveGlobalCov() {
	// Plot the coverage output.
	// log.Printf("Inside SaveGlobalCov function. ")

	// covFile, covOutErr := os.Create("./cov_out.bin")
	// if covOutErr != nil {
	// 	panic(covOutErr)
	// }
	// defer covFile.Close()
	// binary.Write(covFile, binary.LittleEndian, GCov.buf)
	covFile, covOutErr := os.Create("./cov_out.bin")
	if covOutErr != nil {
		panic(covOutErr)
	}
	defer covFile.Close()
	binary.Write(covFile, binary.LittleEndian, GCov.buf)

	var covOutFile *os.File = nil
	if _, err := os.Stat("./cov_str_out.txt"); errors.Is(err, os.ErrNotExist) {
		covOutFile, _ = os.Create("./cov_str_out.txt")
		covOutFile.WriteString("time,coverage\n")
	} else {
		covOutFile, _ = os.OpenFile("./cov_str_out.txt", os.O_WRONLY|os.O_APPEND, 0644)
	}
	defer covOutFile.Close()
	covOutFile.WriteString(fmt.Sprintf("%d,%d\n", time.Now().Unix(), CountNonCov()))

}
