package globalcov

import (
	"bytes"
    "os"
	"encoding/binary"
    //"fmt"
    "log"
)

var GCov GlobalCovInfo

type GlobalCovInfo struct {
	// Default PrevLoc value is 0.
    prevLoc uint32        // Max: 262143 
	buf     bytes.Buffer  // 2 ** 19 buffer size. 
    sBuf    bytes.Buffer  // 2 ** 18 buffer size. 
}

func LogGlobalCov(curLoc uint32) {
	if GCov.buf.Len() == 0 {
		// The GoLang buffer to uint transfer only support uint16 as smallest.
		// Each cov value takes two bytes. Thus 2 ^ (n + 1).
		GCov.buf.Grow(1 << 19)
	}

    //logPrevLoc := GCov.prevLoc
	offset := getXorOffset(curLoc)

    ////Debugging purpose
    //if offset < 66000 && offset > 65000 {
        //log.Printf("\n\n\nDEBUG: Triggered offset: %d, curLoc: %d, prevLoc: %d\n\n\n", offset, curLoc, logPrevLoc)
    //}

    offset = 2 * offset

	count := binary.BigEndian.Uint16(GCov.buf.Bytes()[offset : offset+2])
	count += 1
	binary.BigEndian.PutUint16(GCov.buf.Bytes()[offset : offset+2], count)

}

func getXorOffset(curLoc uint32) uint32 {
	// Get the offset result
	res := GCov.prevLoc ^ curLoc
	// Save the right-shifted curLoc
	GCov.prevLoc = curLoc >> 1
	return res
}

func SaveGlobalCov() {
    // Plot the coverage output. 
    log.Printf("Inside SaveGlobalCov function. ")

	if GCov.sBuf.Len() == 0 {
		// The GoLang buffer to uint transfer only support uint16 as smallest.
		// Each cov value takes two bytes. Thus 2 ^ (n + 1).
		GCov.sBuf.Grow(1 << 18)
	}

    curSBuf := GCov.sBuf.Bytes()
    curBuf := GCov.buf.Bytes()
    for idx, _ := range(curSBuf) {
        curSBuf[idx] = curBuf[idx * 2]
    }

	covFile, covOutErr := os.Create("./cov_out.bin")
	if covOutErr != nil {
		panic(covOutErr)
	}
    defer covFile.Close()
    //log.Printf(fmt.Sprintf("The first few bytes are: %08b,%08b,%08b,%08b", GCov.buf.Bytes()[0], GCov.buf.Bytes()[1], GCov.buf.Bytes()[2], GCov.buf.Bytes()[3]))
    binary.Write(covFile, binary.LittleEndian, GCov.sBuf.Bytes())
    //covFile.Write(GCov.buf.Bytes())
}
