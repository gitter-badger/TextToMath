-- These functions act as the core of the evaluation engine, but should not
-- mutate the environment.  Defining statements are handled by the evalPass

module Calculator.Evaluator.Helpers (
    eval,
    operate
) where

import Calculator.Data.AST
import Calculator.Data.Decimal
import Calculator.Data.Env
import Calculator.Functions
import Control.Applicative ((<$>))
import Control.Monad.State (gets, get, put)
import Control.Monad.StateStack (restore, save)
import qualified Data.Map as Map (lookup, fromList, union)

eval :: AST -> EnvState Decimal
eval (Number n) = return n

eval (Var var) = do
    (Env vars _) <- get
    case Map.lookup var vars of
        Just e -> eval e
        Nothing -> error $ "Use of undefined variable \"" ++ var ++ "\""

eval (Neg e) = negate <$> eval e

eval (OpExpr op leftExpr rightExpr) = do
    leftVal <- eval leftExpr
    rightVal <- eval rightExpr
    return $ operate op leftVal rightVal

eval (FuncExpr func es) = do
    args <- mapM eval es
    case getFunction func of
        Just f -> return $ f args
        Nothing -> do
            funcs <- gets getFuncs
            case Map.lookup func funcs of
                Just f -> evalFunction f args
                Nothing -> error $ "Use of undefined function \"" ++ func ++ "\""

eval ast = error $ "Cannot evaluate the statement " ++ show ast

evalFunction :: Function -> [Decimal] -> EnvState Decimal
evalFunction (Function p b) args = do
    let argVars = Map.fromList $ zip' p $ map Number args
    oldEnv <- get
    -- bring back the original "global" state
    (Env vs fs) <- peek
    -- shadow global vars with params
    put $ Env (Map.union argVars vs) fs
    result <- eval b
    -- restore the original function's environment
    put oldEnv
    return result
    where peek = restore >> save >> get

zip' :: [a] -> [b] -> [(a, b)]
zip' (x:xs) (y:ys) = (x, y) : zip' xs ys
zip' [] [] = []
zip' _ _ = error "Unexpected number of arguments"

operate :: String -> Decimal -> Decimal -> Decimal
operate op n1 n2 =
    case op of
        "+" -> n1 + n2
        "*" -> n1 * n2
        "-" -> n1 - n2
        "/" -> n1 / n2
        "^" -> let sign = n1 / abs n1
               in sign * (abs n1 ** n2)
        "%" -> realMod n1 n2
        o -> error $ "Use of unsupported operator " ++ o
    where realMod a b = a - fromInteger (floor $ a/b) * b
