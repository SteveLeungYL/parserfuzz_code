package main

import "github.com/rsg/rsgGenerator"

func (r *RSG) ClearChosenExpr() {
	// clear the map
	r.curChosenPath = []*rsgGenerator.PathNode{}
	r.pathId = 0
}

func (r *RSG) IncrementSucceed() {

	isFavPath := false
	//fmt.Printf("\nSaving r.curChosenPath size: %d", len(r.curChosenPath))
	//if len(r.curChosenPath) != 0 && r.curChosenPath[0].ExprProds != nil {
	//	fmt.Printf("exprNode: %v\n\n\n", r.curChosenPath[0].ExprProds)
	//}

	for _, curPath := range r.curChosenPath {
		prod := curPath.ExprProds
		//fmt.Printf("\nGetting ExprProds: %v\n", prod)
		if prod == nil {
			continue
		}
		prod.HitCount++
		prod.RewardScore =
			(float64(prod.HitCount-1)/float64(prod.HitCount))*prod.RewardScore + (1.0/float64(prod.HitCount))*1.0
		//fmt.Printf("For expr: %q, hit_count: %d, score: %d\n", prod.Items, prod.HitCount, prod.RewardScore)

		if curPath.IsFav == true {
			isFavPath = true
		}
	}

	// Save the new nodes to the seed.
	if len(r.curChosenPath) != 0 && r.fuzzingMode < fuzzingModeNoFavNoMABNoAcc {
		//fmt.Printf("\n\n\nSaving with type: %s\n\n\n", r.curMutatingType)
		var tmpAllSavedPath [][]*rsgGenerator.PathNode
		tmpAnyAllSavedPath, _ := r.allSavedPath.Load(r.curMutatingType)
		if tmpAnyAllSavedPath != nil {
			tmpAllSavedPath = tmpAnyAllSavedPath.([][]*rsgGenerator.PathNode)
		} else {
			tmpAllSavedPath = [][]*rsgGenerator.PathNode{}
		}

		tmpAllSavedPath = append(tmpAllSavedPath, r.curChosenPath)

		r.allSavedPath.Store(r.curMutatingType, tmpAllSavedPath)
		//fmt.Printf("\nallSavedPath size: %d\n", len(tmpAllSavedPath))
	}

	if len(r.curChosenPath) != 0 && isFavPath == true && r.fuzzingMode < fuzzingModeNoFav {
		var tmpAllSavedFavPath [][]*rsgGenerator.PathNode
		tmpAnyAllSavedFavPath, _ := r.allSavedFavPath.Load(r.curMutatingType)
		if tmpAnyAllSavedFavPath != nil {
			tmpAllSavedFavPath = tmpAnyAllSavedFavPath.([][]*rsgGenerator.PathNode)
		} else {
			tmpAllSavedFavPath = [][]*rsgGenerator.PathNode{}
		}

		tmpAllSavedFavPath = append(tmpAllSavedFavPath, r.curChosenPath)

		r.allSavedFavPath.Store(r.curMutatingType, tmpAllSavedFavPath)
	}

	r.ClearChosenExpr()

}

func (r *RSG) IncrementFailed() {

	isFavPath := false

	for _, curPath := range r.curChosenPath {
		prod := curPath.ExprProds
		if prod == nil {
			continue
		}
		prod.HitCount++
		prod.RewardScore =
			(float64(prod.HitCount-1)/float64(prod.HitCount))*prod.RewardScore + (1.0/float64(prod.HitCount))*0.0
		//fmt.Printf("For expr: %q, hit_count: %d, score: %d\n", prod.Items, prod.HitCount, prod.RewardScore)
		if curPath.IsFav == true {
			isFavPath = true
		}
	}

	if len(r.curChosenPath) != 0 && isFavPath == true && r.fuzzingMode < fuzzingModeNoFav {
		var tmpAllSavedFavPath [][]*rsgGenerator.PathNode
		tmpAnyAllSavedFavPath, _ := r.allSavedFavPath.Load(r.curMutatingType)
		if tmpAnyAllSavedFavPath != nil {
			tmpAllSavedFavPath = tmpAnyAllSavedFavPath.([][]*rsgGenerator.PathNode)
		} else {
			tmpAllSavedFavPath = [][]*rsgGenerator.PathNode{}
		}

		tmpAllSavedFavPath = append(tmpAllSavedFavPath, r.curChosenPath)

		r.allSavedFavPath.Store(r.curMutatingType, tmpAllSavedFavPath)
	}

	r.ClearChosenExpr()
}

func (r *RSG) SaveFav() {

	isFavPath := false

	for _, curPath := range r.curChosenPath {
		prod := curPath.ExprProds
		if prod == nil {
			continue
		}
		if curPath.IsFav == true {
			isFavPath = true
		}
	}

	if len(r.curChosenPath) != 0 && isFavPath == true {
		var tmpAllSavedFavPath [][]*rsgGenerator.PathNode
		tmpAnyAllSavedFavPath, _ := r.allSavedFavPath.Load(r.curMutatingType)
		if tmpAnyAllSavedFavPath != nil {
			tmpAllSavedFavPath = tmpAnyAllSavedFavPath.([][]*rsgGenerator.PathNode)
		} else {
			tmpAllSavedFavPath = [][]*rsgGenerator.PathNode{}
		}

		tmpAllSavedFavPath = append(tmpAllSavedFavPath, r.curChosenPath)

		r.allSavedFavPath.Store(r.curMutatingType, tmpAllSavedFavPath)
	}

	// No need to clear path in this function.
}
