module Main

{-  monads and system from potpourri by

guillaume allais: https://github.com/gallais/potpourri/blob/e7649e40e56d67e88791228aac33dc995be79cd2/idris/poc/LinEff.idr#L4
-}

import System.

{- redefine the dotted expression, composition operator -}
private infixr 9 <.>
(<.>) : (b -> c) -> (a -> b) -> a -> c

{- define a result type -}
Res : List Type -> Type
Res [] = ()
Res (a :: as)

{- based on haskell's List Comprehension
Pattern Matching syntax: the "xs".

"In pattern matching, we attempt to match values
against patterns and, if so desired, bind variables
to successful matches." -}

interface Member (0 t : Type) (0 ts : List Type) where
  0 Leftovers' : List Type
  remove : (1 _ : Res ts) -> LPair t (Res Leftovers')
  insert : (1 _ : LPair t (Res Leftovers')) -> Res ts

0 Leftovers' : (0 t : Type) -> (0 ts : List Type) -> Member t ts => List Type




(>>=) : M res1 res2 a -> (a -> M res2 res3 b) -> M res1 res3 b
(>>=) = Bind


main : IO ()
main = putStrLn "========\n"

{- Types and functions-}
-- Types
module Prims

x : Int
x = 94

foo : String
foo = "a grey fox jumps over the wall"

bar : Char
bar = 'Z'

quux : Bool
quux = False

--- functions-

---- unary addition
plus : Nat -> Nat -> Nat
plus Z y = y
plus (S k) y = S

---- unary multiplication
mult :


{- Linear Resources -}

(>>=) : SafeBind l l' =>
     App {l} e a -> (a -> App {l=l'} e b) -> App {l=l'} e b
