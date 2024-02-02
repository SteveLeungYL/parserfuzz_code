package globalcov

import (
	"encoding/binary"
	"log"
	"os"
)

var GCov GlobalCovInfo

type GlobalCovInfo struct {
	// Default PrevLoc value is 0.
	prevLoc uint32         // Max: 262143
	buf     [1 << 18]uint8 // trace_bit buffer. 262144 size.
}

func LogGlobalCov(curLoc uint32) {

	// offset := getXorOffset(curLoc)
	offset := curLoc

	/* With hit count. */
	// Prevent overflow.
	// if GCov.buf[offset] != 255 {
	// 	GCov.buf[offset] = 1
	// }

	/* Without hit count. */
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
