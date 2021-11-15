module Main exposing (initialModel, main, urlPrefix, view)

import Browser
import Html exposing (Html, div, h1, img, text)
import Html.Attributes exposing (class, classList, id, src)
import Html.Events exposing (onClick)


type alias Photo =
    { url : String }


type alias Model =
    { photos : List Photo, selectedUrl : String }


type alias Msg =
    { description : String, data : String }


initialModel : Model
initialModel =
    { photos = [ { url = "1.jpeg" }, { url = "2.jpeg" }, { url = "3.jpeg" } ], selectedUrl = "1.jpeg" }


main =
    Browser.sandbox
        { init = initialModel
        , view = view
        , update = update
        }


view model =
    div [ class "content" ] [ header, thumbnails model, largePhoto model ]


header =
    h1 [] [ text "Photo Booth" ]


thumbnails : Model -> Html Msg
thumbnails model =
    div [ id "thumbnails" ] (List.map (viewThumbnail model.selectedUrl) model.photos)


largePhoto model =
    img [ src (urlPrefix ++ "large/" ++ model.selectedUrl), class "large" ] []



{- update -}


update msg model =
    if msg.description == "ClickedPhoto" then
        { model | selectedUrl = msg.data }

    else
        model



{- Helper functions -}


urlPrefix =
    "https://elm-in-action.com/"


viewThumbnail selectedUrl photo =
    img
        [ src (urlPrefix ++ photo.url)
        , classList [ ( "selected", photo.url == selectedUrl ) ]
        , onClick { description = "ClickedPhoto", data = photo.url }
        ]
        []
