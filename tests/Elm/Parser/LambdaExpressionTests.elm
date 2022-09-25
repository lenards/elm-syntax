module Elm.Parser.LambdaExpressionTests exposing (all)

import Combine
import Elm.Parser.CombineTestUtil exposing (..)
import Elm.Parser.Declarations as Parser
import Elm.Parser.Layout as Layout
import Elm.Parser.State exposing (emptyState)
import Elm.Syntax.Expression exposing (..)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Pattern exposing (..)
import Elm.Syntax.Range exposing (..)
import Expect
import Test exposing (..)


all : Test
all =
    describe "LambdaExpressionTests"
        [ test "unit lambda" <|
            \() ->
                parseFullStringState emptyState "\\() -> foo" Parser.expression
                    |> Maybe.map (Node.value >> noRangeInnerExpression)
                    |> Expect.equal
                        (Just
                            (LambdaExpression
                                { arguments = [ Node emptyRange UnitPattern ]
                                , expression = Node emptyRange <| FunctionOrValue [] "foo"
                                }
                            )
                        )
        , test "record lambda" <|
            \() ->
                parseFullStringState emptyState "\\{foo} -> foo" Parser.expression
                    |> Maybe.map (Node.value >> noRangeInnerExpression)
                    |> Expect.equal
                        (Just
                            (LambdaExpression
                                { arguments = [ Node emptyRange (RecordPattern [ Node { end = { column = 0, row = 0 }, start = { column = 0, row = 0 } } "foo" ]) ]
                                , expression = Node emptyRange <| FunctionOrValue [] "foo"
                                }
                            )
                        )
        , test "empty record lambda" <|
            \() ->
                parseFullStringState emptyState "\\{} -> foo" Parser.expression
                    |> Maybe.map (Node.value >> noRangeInnerExpression)
                    |> Expect.equal
                        (Just
                            (LambdaExpression
                                { arguments = [ Node emptyRange (RecordPattern []) ]
                                , expression = Node emptyRange <| FunctionOrValue [] "foo"
                                }
                            )
                        )
        , test "function argument" <|
            \() ->
                parseAsFarAsPossibleWithState emptyState "a b" Parser.functionArgument
                    |> Maybe.map Node.value
                    |> Expect.equal
                        (Just (VarPattern "a"))
        , test "arguments lambda" <|
            \() ->
                parseFullStringState emptyState "\\a b -> a + b" Parser.expression
                    |> Maybe.map (Node.value >> noRangeInnerExpression)
                    |> Expect.equal
                        (Just
                            (LambdaExpression
                                { arguments =
                                    [ Node emptyRange <| VarPattern "a"
                                    , Node emptyRange <| VarPattern "b"
                                    ]
                                , expression =
                                    Node emptyRange <|
                                        Application
                                            [ Node emptyRange <| FunctionOrValue [] "a"
                                            , Node emptyRange <| Operator "+"
                                            , Node emptyRange <| FunctionOrValue [] "b"
                                            ]
                                }
                            )
                        )
        , test "tuple lambda" <|
            \() ->
                parseFullStringState emptyState "\\(a,b) -> a + b" Parser.expression
                    |> Maybe.map (Node.value >> noRangeInnerExpression)
                    |> Expect.equal
                        (Just
                            (LambdaExpression
                                { arguments =
                                    [ Node emptyRange <|
                                        TuplePattern
                                            [ Node emptyRange <| VarPattern "a"
                                            , Node emptyRange <| VarPattern "b"
                                            ]
                                    ]
                                , expression = Node emptyRange <| Application [ Node emptyRange <| FunctionOrValue [] "a", Node emptyRange <| Operator "+", Node emptyRange <| FunctionOrValue [] "b" ]
                                }
                            )
                        )
        , test "lambda with trailing whitespace" <|
            \() ->
                parseFullStringState emptyState " \\a b -> a + b\n\n\n\n--some comment\n" (Layout.layout |> Combine.continueWith Parser.expression)
                    |> Maybe.map Node.range
                    |> Expect.equal (Just { end = { column = 15, row = 1 }, start = { column = 2, row = 1 } })
        ]
