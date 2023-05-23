#include "ParserDataflow.h""

#define endl "\n"

using namespace llvm;

char ParserDataflow::ID = 0;

bool ParserDataflow::runOnModule(Module &M) {

  LLVMContext &C = M.getContext();

  IntegerType *Int1Ty = IntegerType::getInt1Ty(C);
  PointerType *Ptr8Ty = PointerType::getInt8PtrTy(C);

  std::vector<Type *> args = {Int1Ty, Ptr8Ty};
  auto *helpTy = FunctionType::get(Type::getVoidTy(C), args, false);
  Function *check_iden_var = dyn_cast<Function>(M.getOrInsertFunction("check_iden_variable", helpTy));

  for (auto & F : M) {

    if (F.getName() == "check_iden_variable") continue;

    for (auto & BB : F) {

      for (auto & I : BB) {

        if (isa<StoreInst>(I)) {
          
          StoreInst * BI = cast<StoreInst>(&I);
          
          if (BI->isUnconditional()) continue;

          // errs() << I << "\n";

          IRBuilder<> IRB(&I);
          std::vector<Value *> real_args = {BI->getCondition(), 
            IRB.getInt64(branch_id++)};
          IRB.CreateCall(check_label, real_args);

        }

        if (isa<CallInst>(I)) {

          CallInst * CI = cast<CallInst>(&I);

          if (CI->getCalledFunction() == nullptr) continue;

          if (CI->getCalledFunction()->getName() == "fread") {

            calls.push_back(CI);

          }
        }
      }
    }
  }

  for (auto I : calls) {

    assert(my_fread_func != nullptr);

    CallInst * CI  = I;
    IRBuilder<> IRB(CI);

    std::vector<Value *> real_args;
    for (unsigned index = 0; index < CI->getNumArgOperands(); index++)
      real_args.push_back(CI->getArgOperand(index));
    real_args.push_back(IRB.getInt64(fread_id++));
    auto res = IRB.CreateCall(myfread_func, real_args);
    CI->replaceAllUsesWith(res);
    //CI->removeFromParent();
    CI->eraseFromParent();

  }

  return true;
}

static RegisterPass<ParserDataflow> X("ParserDataflow", "trace the parser Identifier values to the variable back-end ");

static void registerParserDataflow(const PassManagerBuilder &,
    legacy::PassManagerBase &PM) {
  PM.add(new ParserDataflow());
}

static RegisterStandardPasses RegisterParserDataflowPass(
    //PassManagerBuilder::EP_OptimizerLast, registerCmpDataflowPass);
    //PassManagerBuilder::EP_EarlyAsPossible, registerCmpDataflowPass);
    PassManagerBuilder::EP_ModuleOptimizerEarly, registerParserDataflow);
static RegisterStandardPasses RegisterParserDataflowPass0(
    PassManagerBuilder::EP_EnabledOnOptLevel0, registerParserDataflowPass);
