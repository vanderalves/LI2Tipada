module Interpreter where

import AbsLI
import PrintLI
import Prelude hiding (lookup)

executeP :: Program -> Environment
executeP (Prog fs) = execute (updatecF ([], []) fs) (SBlock (stmMain fs))
  where
    stmMain ((Fun _ (Ident "main") decls stms) : xs) = stms
    stmMain (_ : xs) = stmMain xs

execute :: Environment -> Stm -> Environment
execute environment x = case x of
    SDec (Dec tp id) -> updateShallowValue environment id (initVal tp)
    SAss id exp -> updateDeepValue environment id (eval environment exp)
    SBlock [] -> environment
    SBlock (sb@(SBlock bls) : stms) -> execute (pop (execute (push environment) sb)) (SBlock stms)
    SBlock (s : stms) -> execute (execute environment s) (SBlock stms)
    SWhile exp stm ->
        if (i (eval environment exp) /= 0)
            then execute (execute environment stm) (SWhile exp stm)
            else environment
    SReturn exp -> updateShallowValue environment (Ident "return") (eval environment exp)
    SIf exp stmT stmE ->
        if (i (eval environment exp) /= 0)
            then execute environment stmT
            else execute environment stmE

eval :: Environment -> Exp -> Valor
eval environment x = case x of
    ECon exp0 exp -> ValorStr (s (eval environment exp0) ++ s (eval environment exp))
    EAdd exp0 exp -> ValorInt (i (eval environment exp0) + i (eval environment exp))
    ESub exp0 exp -> ValorInt (i (eval environment exp0) - i (eval environment exp))
    EMul exp0 exp -> ValorInt (i (eval environment exp0) * i (eval environment exp))
    EDiv exp0 exp -> ValorInt (i (eval environment exp0) `div` i (eval environment exp))
    EOr exp0 exp -> ValorBool (b (eval environment exp0) || b (eval environment exp))
    EAnd exp0 exp -> ValorBool (b (eval environment exp0) && b (eval environment exp))
    ENot exp -> ValorBool (not (b (eval environment exp)))
    EStr str -> ValorStr str
    ETrue -> ValorBool True
    EFalse -> ValorBool False
    EInt n -> ValorInt n
    EVar id -> lookupDeepValue environment id
    Call id lexp ->
        lookupShallowValue
            (execute ([paramBindings], (snd environment)) (SBlock stms))
            (Ident "return")
      where
        ValorFun (Fun _ _ decls stms) = lookupShallowFunction environment id
        paramBindings =
            zip
                (map (\(Dec _ id) -> id) decls)
                (map (eval environment) lexp)
    ENil -> ValorList []
    ECons e1 e2 -> ValorList $ (eval environment e1) : (l (eval environment e2))
    EIsNil exp -> ValorBool $ null $ l $ eval environment exp
    EHead exp -> head $ l $ eval environment exp
    ETail exp -> ValorList $ tail $ l $ eval environment exp
    EPair e1 e2 -> ValorPair (eval environment e1) (eval environment e2)
    EFst exp -> fst $ p $ eval environment exp
    ESnd exp -> snd $ p $ eval environment exp

data Valor
    = ValorInt
        { i :: Integer
        }
    | ValorFun
        { f :: Function
        }
    | ValorStr
        { s :: String
        }
    | ValorBool
        { b :: Bool
        }
    | ValorList
        { l :: [Valor]
        }
    | ValorPair
        { p :: (Valor, Valor)
        }

initVal :: Type -> Valor
initVal Tbool = ValorBool False
initVal Tint = ValorInt 0
initVal TStr = ValorStr ""
initVal (TList _) = ValorList []
initVal (TPair ft st) = ValorPair (initVal ft) (initVal st)

instance Show Valor where
    show (ValorBool b) = show b
    show (ValorInt i) = show i
    show (ValorStr s) = s
    show (ValorFun (Fun tp _ decls _)) = printTree tp ++ "<-" ++ "(" ++ printTree decls ++ ")"
    show (ValorList l) = show l
    show (ValorPair p) = show p

-- (\(Ident x) -> x) nf

{-
type Environment = [(Ident,Valor)]

lookup :: Environment -> Ident -> Valor
lookup ((i,v):cs) s
   | i == s = v
   | otherwise = lookup cs s

update :: Environment -> Ident -> Valor -> Environment
update [] s v = [(s,v)]
update ((i,v):cs) s nv
  | i == s = (i,nv):cs
  | otherwise = (i,v) : update cs s nv

updatecF :: Environment -> [Function] -> Environment
updatecF c [] = c
updatecF c (f@(Fun tp id params stms):fs) = updatecF (update c id (ValorFun f)) fs

-}

data R a = OK a | Erro String
    deriving (Eq, Ord, Show, Read)

type Environment = ([RContext], RContext)
type RContext = [(Ident, Valor)]

pushB :: RContext -> Environment -> Environment
pushB typeBindings (sc, fnCtx) = (typeBindings : sc, fnCtx)

push :: Environment -> Environment
push (sc, fnCtx) = ([] : sc, fnCtx)

pop :: Environment -> Environment
pop ((s : scs), fnCtx) = (scs, fnCtx)

lookupDeepValue :: Environment -> Ident -> Valor
-- lookupDeepType ([],fnCtx) id = Erro (printTree id ++ " nao esta no contexto. ")
lookupDeepValue ((s : scs), fnCtx) id =
    let r = lookupShallow s id
     in case r of
            OK val -> val
            Erro _ -> lookupDeepValue (scs, fnCtx) id

lookupShallowValue :: Environment -> Ident -> Valor
lookupShallowValue ((s : sc), _) id = (\(OK val) -> val) (lookupShallow s id)

lookupShallowFunction :: Environment -> Ident -> Valor
lookupShallowFunction (_, fnCtx) id = (\(OK val) -> val) (lookupShallow fnCtx id)

lookupShallow :: RContext -> Ident -> R Valor
lookupShallow [] s = Erro (show s ++ " nao esta no contexto. ")
lookupShallow ((i, v) : cs) s
    | i == s = OK v
    | otherwise = lookupShallow cs s

updateShallowValue :: Environment -> Ident -> Valor -> Environment
updateShallowValue ([], fnCtx) id tp = ([[(id, tp)]], fnCtx)
updateShallowValue ((s : sc), fnCtx) id tp = ((updateShallow s id tp) : sc, fnCtx)

updateDeepValue :: Environment -> Ident -> Valor -> Environment
updateDeepValue ([], fnCtx) id tp = ([[(id, tp)]], fnCtx)
updateDeepValue ((s : sc), fnCtx) id tp =
    let r = lookupShallow s id
     in case r of
            OK _ -> ((updateShallow s id tp) : sc, fnCtx)
            Erro _ -> pushB s (updateDeepValue (sc, fnCtx) id tp)

-- note that, differently from the typechecker, updating an existing value is possible
updateShallow :: RContext -> Ident -> Valor -> RContext
updateShallow [] s nv = [(s, nv)]
updateShallow ((i, v) : cs) s nv
    | i == s = (i, nv) : cs
    | otherwise = (i, v) : updateShallow cs s nv

updatecF :: Environment -> [Function] -> Environment
updatecF e [] = e
updatecF (sc, c) (f@(Fun tp id params stms) : fs) = updatecF (sc, updateShallow c id (ValorFun f)) fs
