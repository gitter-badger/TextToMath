module Calculator.Data.AST (
    AST(..)
) where

data AST = EqlStmt AST AST
           | OpExpr String AST AST
           | FuncExpr String [AST]
           | Var String
           | Number String
           | Neg AST
           deriving (Show, Eq)
