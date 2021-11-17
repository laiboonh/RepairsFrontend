module MainTests exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Html.Attributes as Attr
import Main exposing (Model, Msg(..), Status(..), ThumbnailSize(..), urlPrefix, view)
import Test exposing (..)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector exposing (attribute, classes, tag)


photos =
    [ { url = "1.jpeg", size = 1, title = "" }, { url = "2.jpeg", size = 1, title = "" }, { url = "3.jpeg", size = 1, title = "" } ]


initialModel : Model
initialModel =
    { status = Loaded photos (Just "1.jpeg"), chosenSize = Medium }


renderImage : Test
renderImage =
    test "renders 3 thumbnails and 1 large photo"
        (\_ ->
            initialModel
                |> view
                |> Query.fromHtml
                |> Query.findAll [ tag "img" ]
                |> Query.count (Expect.equal 4)
        )


initialSelected : Test
initialSelected =
    test "initial selected"
        (\_ ->
            initialModel
                |> view
                |> Query.fromHtml
                |> Query.findAll [ tag "img" ]
                |> Query.first
                |> Query.has [ classes [ "selected" ] ]
        )


photoClick : Test
photoClick =
    test "Click on photo makes it the selected photo"
        (\_ ->
            let
                selectedUrl =
                    "2.jpeg"
            in
            initialModel
                |> view
                |> Query.fromHtml
                |> Query.find [ tag "img", attribute (Attr.src (urlPrefix ++ selectedUrl)) ]
                |> Event.simulate Event.click
                |> Event.expect (ClickedPhoto selectedUrl)
        )
