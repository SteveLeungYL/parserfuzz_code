/*

execute_params:

    expr_or_ignore_or_default {
        auto tmp1 = $1;
        res = new IR(kExecuteParams, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | execute_params ',' expr_or_ignore_or_default {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExecuteParams, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


execute:

    EXECUTE_SYM ident execute_using {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kExecute, OP3("EXECUTE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | EXECUTE_SYM IMMEDIATE_SYM {} expr {} execute_using {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kExecute_1, OP3("EXECUTE", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kExecute, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;