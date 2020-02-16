{-# LANGUAGE CPP #-}

#ifdef TEST
module NGramModel where
#else
module NGramModel
    ( NGramModel
    , makeModel
    ) where
#endif

import Data.Map.Strict (Map)
import qualified Data.Map.Strict as M (lookup, insert, empty, singleton)

data TextWord =
    TextStart |
    Literal String

instance Eq TextWord where
    (==) TextStart (Literal _) = False
    (==) TextStart TextStart = True
    (==) (Literal s) (Literal t) = s == t
    (==) (Literal _) TextStart = False

instance Ord TextWord where
    compare TextStart (Literal _) = LT
    compare TextStart TextStart = EQ
    compare (Literal s) (Literal t) = compare s t
    compare (Literal _) TextStart = GT

    (<=) TextStart (Literal _) = True
    (<=) TextStart TextStart = True
    (<=) (Literal s) (Literal t) = s <= t
    (<=) (Literal _) TextStart = False

instance Show TextWord where
    show tw =
        case tw of
            TextStart -> "<TextStart>"
            Literal s -> s

data WordMap =
    WordMap (Map TextWord WordMap) |
    Count Word

instance Eq WordMap where
    (==) (WordMap m1) (WordMap m2) = m1 == m2
    (==) (WordMap _) (Count _) = False
    (==) (Count _) (WordMap _) = False
    (==) (Count i1) (Count i2) = i1 == i2

instance Show WordMap where
    show wm =
        case wm of
            WordMap m -> show m
            Count i -> show i

data NGramModel = NGramModel
    { ngm_n :: Int
    , ngm_data :: WordMap
    }

makeModel :: Int -> String -> NGramModel
makeModel n text =
    NGramModel { ngm_n = n, ngm_data = parse (n - 1) text }

tokenize :: String -> [String]
tokenize = words

constructMap :: Int -> [String] -> WordMap
constructMap numPreceding =
    constructMapRecurse $ replicate numPreceding TextStart

constructMapRecurse :: [TextWord] -> [String] -> WordMap
constructMapRecurse preceding (first : rest) =
    addToMap restMap wordList
    where
        wordList = preceding ++ [Literal first]
        restMap = constructMapRecurse (tail wordList) rest
constructMapRecurse _preceding [] = WordMap M.empty

addToMap :: WordMap -> [TextWord] -> WordMap
addToMap (WordMap m) (first : rest) =
    case M.lookup first m of
        Just m' -> addToMap m' rest
        Nothing -> WordMap $ M.insert first newSubMap m
    where
        newSubMap = addToMap (Count 0) rest
addToMap (WordMap m) [] = WordMap m
addToMap (Count c) (first : rest) =
    WordMap $ M.singleton first subMap
    where
        subMap = addToMap (Count c) rest
addToMap (Count c) [] = Count $ c + 1

parse :: Int -> String -> WordMap
parse numPreceding =
    constructMap numPreceding . tokenize
