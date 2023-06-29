#include "llvm/IR/Function.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/IPO/PassManagerBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"

#include <vector>

using namespace llvm;

namespace {

  class ParserDataflow : public ModulePass {

    public:
      static char ID;
      ParserDataflow() : ModulePass(ID) { }

      bool runOnModule(Module &M) override;
  };
}

