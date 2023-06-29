#include "ParserDataflow.h"

#define endl "\n"

using namespace llvm;

char ParserDataflow::ID = 0;

bool ParserDataflow::runOnModule(Module &M) {

  LLVMContext &C = M.getContext();

  IntegerType *Int8Ty = IntegerType::getInt8Ty(C);
  PointerType *Ptr64Ty = PointerType::getInt64PtrTy(C);

  std::vector<Type *> args = {Int8Ty, Ptr64Ty};
  auto *helpTy = FunctionType::get(Type::getVoidTy(C), args, false);
  Function *check_iden_var = dyn_cast<Function>(M.getOrInsertFunction("check_iden_variable", helpTy));


  for (auto & F : M) {

    fprintf(stderr, "Function iteration, getting name: %s\n", F.getName().data());
    if (F.getName() == "check_iden_variable") {
      fprintf(stderr, "func skipped\n\n\n");
      continue;
    }

    for (auto & BB : F) {

      for (auto & I : BB) {

        if (isa<StoreInst>(I)) {
          
          StoreInst * SI = cast<StoreInst>(&I);
          fprintf(stderr, "After casting\n");

          if (SI->getPointerOperand() == nullptr || SI->getPointerOperand()->getName().empty()) {
            continue;
          }

          IRBuilder<> IRB(&I);
          printf("Getting operand name: %s\n\n", SI->getPointerOperand()->getName().data());
          auto *dest_var_name_ptr = IRB.CreateGlobalStringPtr(SI->getPointerOperand()->getName().data());
          std::vector<Value *> real_args = {SI->getPointerOperand(), dest_var_name_ptr};
          IRB.CreateCall(check_iden_var, real_args);
        }
      }
    }
  }

  fprintf(stderr, "Finished. \n\n\n");

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
