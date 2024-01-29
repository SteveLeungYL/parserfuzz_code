package edgeClassifier

func IsSqliteCompNode(_ string, nodeValue string) bool {
	switch nodeValue {
	case "select":
		fallthrough
	case "expr":
		return true
	}
	return false
}
