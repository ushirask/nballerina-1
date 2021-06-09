import wso2/nballerina.err;

function parseExpr(Tokenizer tok) returns Expr|err:Syntax {
    return parseAdditiveExpr(tok);
}

function parseAdditiveExpr(Tokenizer tok) returns Expr|err:Syntax {
    Expr expr = check parseMultiplicativeExpr(tok);
    while true {
        Token? t = tok.current();
        if t is ("+"|"-") {
            BinaryExprOp op = t;
            check tok.advance();
            Expr right = check parseMultiplicativeExpr(tok);
            BinaryExpr bin = { op, left: expr, right };
            expr = bin;
        } 
        else {
            break;
        }
    }
    return expr;
}

function parseMultiplicativeExpr(Tokenizer tok) returns Expr|err:Syntax {
    Expr expr = check parsePrimaryExpr(tok);
    while true {
        Token? t = tok.current();
        if t is ("*"|"/"|"%") {
            BinaryExprOp op = t;
            check tok.advance();
            Expr right = check parsePrimaryExpr(tok);
            BinaryExpr bin = { op, left: expr, right };
            expr = bin;
        } 
        else {
            break;
        }
    }
    return expr;
}

function parsePrimaryExpr(Tokenizer tok) returns Expr|err:Syntax {
    Token? t = tok.current();
    if t is [IDENTIFIER, string] {
        err:Position pos = tok.currentPos();
        string identifier = t[1];
        VarRefExpr expr = { varName: identifier };
        check tok.advance();
        t = tok.current();
        if t == "(" {
            return finishFunctionCallExpr(tok, identifier, pos);
        }
        return expr;
    } 
    else if t is [DECIMAL_NUMBER, string] {
        SimpleConstExpr expr = { value: check parseDigits(tok, t[1]) };
        return expr;
    }
    else if t == "(" {
        check tok.advance();
        Expr expr = check parseExpr(tok);
        check tok.expect(")");
        return expr;
    }
    else {
        return parseError(tok);
    }
}

// current token is the "("
function finishFunctionCallExpr(Tokenizer tok, string funcName, err:Position pos) returns FunctionCallExpr|err:Syntax {
    check tok.advance();
    Expr[] args = [];
    if tok.current() != ")" {
        while true {
            Expr arg = check parseExpr(tok);
            args.push(arg);
            Token? t = tok.current();
            if t == "," {
                check tok.advance();
            }
            else if t == ")" {
                break;
            }
            else {
                return parseError(tok, "invalid function argument");
            }
        }
    }
    check tok.advance();
    return { funcName, pos, args };
}

function parseConstExpr(Tokenizer tok) returns TypeDesc|err:Syntax {
    check tok.expect("=");
    string sign = "";
    if tok.current() == "-" {
        check tok.advance();
        sign = "-";
    }
    match tok.current() {
        [DECIMAL_NUMBER, var digits] => {
            SingletonTypeDesc td = { value: check parseDigits(tok, sign + digits) };
            return td;
        // JBUG this gets a bad sad #30738
        // NullPointerException in BIROptimizer$RHSTempVarOptimizer.visit
        // int n;
        // do {
        //     n = check int:fromString(sign + digits);
        // } on fail var cause {
        //     return err:syntax("invalid number", cause, pos=tok.currentPos());
        // }
        // check tok.advance();
        // return <SingletonTypeDesc>{ value: n };         
        }
    }
    return parseError(tok);
}

function parseDigits(Tokenizer tok, string signDigits) returns int|err:Syntax {
    error|int res = int:fromString(signDigits);
    if res is error {
        return err:syntax("invalid number", tok.currentPos(), res);
    } 
    else {
        check tok.advance();
        return res;
    }
}
