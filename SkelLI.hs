-- File generated by the BNF Converter (bnfc 2.9.4.1).

-- Templates for pattern matching on abstract syntax

{-# OPTIONS_GHC -fno-warn-unused-matches #-}

module SkelLI where

import Prelude (($), Either(..), String, (++), Show, show)
import qualified AbsLI

type Err = Either String
type Result = Err String

failure :: Show a => a -> Result
failure x = Left $ "Undefined case: " ++ show x

transIdent :: AbsLI.Ident -> Result
transIdent x = case x of
  AbsLI.Ident string -> failure x

transProgram :: AbsLI.Program -> Result
transProgram x = case x of
  AbsLI.Prog functions -> failure x

transFunction :: AbsLI.Function -> Result
transFunction x = case x of
  AbsLI.Fun type_ ident decls stms -> failure x

transDecl :: AbsLI.Decl -> Result
transDecl x = case x of
  AbsLI.Dec type_ ident -> failure x

transStm :: AbsLI.Stm -> Result
transStm x = case x of
  AbsLI.SDec decl -> failure x
  AbsLI.SAss ident exp -> failure x
  AbsLI.SBlock stms -> failure x
  AbsLI.SWhile exp stm -> failure x
  AbsLI.SReturn exp -> failure x
  AbsLI.SIf exp stm1 stm2 -> failure x

transExp :: AbsLI.Exp -> Result
transExp x = case x of
  AbsLI.EOr exp1 exp2 -> failure x
  AbsLI.EAnd exp1 exp2 -> failure x
  AbsLI.ENot exp -> failure x
  AbsLI.ECon exp1 exp2 -> failure x
  AbsLI.EAdd exp1 exp2 -> failure x
  AbsLI.ESub exp1 exp2 -> failure x
  AbsLI.EMul exp1 exp2 -> failure x
  AbsLI.EDiv exp1 exp2 -> failure x
  AbsLI.Call ident exps -> failure x
  AbsLI.EInt integer -> failure x
  AbsLI.EVar ident -> failure x
  AbsLI.EStr string -> failure x
  AbsLI.ETrue -> failure x
  AbsLI.EFalse -> failure x

transType :: AbsLI.Type -> Result
transType x = case x of
  AbsLI.Tbool -> failure x
  AbsLI.Tint -> failure x
  AbsLI.Tvoid -> failure x
  AbsLI.TStr -> failure x
  AbsLI.TFun function -> failure x
