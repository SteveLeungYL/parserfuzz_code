package constant_structs

// Constant Values
type FuzzingMode int

const (
	FuzzingModeNormal               FuzzingMode = 0 // Enable all ParserFuzz features
	FuzzingModeNoFav                FuzzingMode = 1 // Disable unseen rule prioritization
	FuzzingModeNoFavNoMAB           FuzzingMode = 2 // Further disable MAB based rule prioritization
	FuzzingModeNoFavNoMABNoAcc      FuzzingMode = 3 // Further disable Categorization-based rule prioritization
	FuzzingModeNoFavNoMABNoAccNoCat FuzzingMode = 4 // Further disable the accumulative mutations
)

var (
	FuzzingModeMap = map[string]FuzzingMode{
		"normal":               FuzzingModeNormal,
		"noFav":                FuzzingModeNoFav,
		"noFavNoMAB":           FuzzingModeNoFavNoMAB,
		"noFavNoMABNoAcc":      FuzzingModeNoFavNoMABNoAcc,
		"noFavNoMABNoAccNoCat": FuzzingModeNoFavNoMABNoAccNoCat,
	}
)
