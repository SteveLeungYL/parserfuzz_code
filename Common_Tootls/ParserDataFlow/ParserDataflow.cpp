#include "ParserDataflow.h"

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
          
          StoreInst * SI = cast<StoreInst>(&I);
          IRBuilder<> IRB(&I);
          auto *dest_var_name_ptr = IRB.CreateGlobalStringPtr(SI->getPointerOperand()->getName().data());
          std::vector<Value *> real_args = {SI->getPointerOperand(), dest_var_name_ptr};
          IRB.CreateCall(check_iden_var, real_args);
        }
      }
    }
  }

  return true;
}

static RegisterPass<ParserDataflow> X("ParserDataflow", "trace the parser Identifier values to the variable back-end ");

static void registerParserDataflowPass(const PassManagerBuilder &,
    legacy::PassManagerBase &PM) {
  PM.add(new ParserDataflow());
}

static RegisterStandardPasses RegisterParserDataflowPass(
    //PassManagerBuilder::EP_OptimizerLast, registerCmpDataflowPass);
    //PassManagerBuilder::EP_EarlyAsPossible, registerCmpDataflowPass);
    PassManagerBuilder::EP_ModuleOptimizerEarly, registerParserDataflowPass);

static RegisterStandardPasses RegisterParserDataflowPass0(
    PassManagerBuilder::EP_EnabledOnOptLevel0, registerParserDataflowPass);
