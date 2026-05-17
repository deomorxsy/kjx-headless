module Main

main : IO ()
main = putStrLn "Hello world"

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
