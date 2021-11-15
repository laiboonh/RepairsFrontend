module MainTests exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Main exposing (initialModel, view)
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (tag)


suite : Test
suite =
    test "renders 3 thumbnails"
        (\_ ->
            initialModel
                |> view
                |> Query.fromHtml
                |> Query.findAll [ tag "img" ]
                |> Query.count (Expect.equal 3)
        )
