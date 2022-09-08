package global_cov

import (
	"bytes"
	"encoding/binary"
	"log"
)

var GCov GlobalCovInfo

type GlobalCovInfo struct {
	// Default PrevLoc value is 0.
	prevLoc uint32
	buf     bytes.Buffer
}

func (g *GlobalCovInfo) LogGlobalCov(curLoc uint32) {
	if g.buf.Len() == 0 {
		// The GoLang buffer to uint transfer only support uint16 as smallest.
		// Each cov value takes two bytes. Thus 2 ^ (n + 1).
		g.buf.Grow(1 << 19)
	}

	offset := 2 * g.getXorOffset(curLoc)
	log.Printf("Logging for offset: %d", offset)
	count := binary.BigEndian.Uint16(g.buf.Bytes()[offset : offset+2])
	count += 1
	binary.BigEndian.PutUint16(g.buf.Bytes()[offset:offset+2], count)

	return
}

func (g *GlobalCovInfo) getXorOffset(curLoc uint32) uint32 {
	// Get the offset result
	res := g.prevLoc ^ curLoc
	// Save the right-shifted curLoc
	g.prevLoc = curLoc >> 1
	return res
}

