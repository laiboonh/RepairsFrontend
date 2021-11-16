module Main exposing (Msg(..), initialModel, main, urlPrefix, view)

import Browser
import Html exposing (Html, button, div, h1, h3, img, input, label, text)
import Html.Attributes exposing (class, classList, id, name, src, type_)
import Html.Events exposing (onClick)


type alias Photo =
    { url : String }


type alias Model =
    { photos : List Photo, selectedUrl : String, chosenSize : ThumbnailSize }


type Msg
    = ClickedPhoto String
    | ClickedSize ThumbnailSize
    | ClickedSurpriseMe


type ThumbnailSize
    = Small
    | Medium
    | Large


initialModel : Model
initialModel =
    { photos = [ { url = "1.jpeg" }, { url = "2.jpeg" }, { url = "3.jpeg" } ], selectedUrl = "1.jpeg", chosenSize = Medium }


main =
    Browser.sandbox
        { init = initialModel
        , view = view
        , update = update
        }


view model =
    div [ class "content" ] [ header, viewSizeChooserTitle, viewSizeChooser, surpriseButton, thumbnails model, largePhoto model ]


header =
    h1 [] [ text "Photo Booth" ]


viewSizeChooserTitle =
    h3 [] [ text "Thumbnail Size" ]


viewSizeChooser =
    div [ id "choose-size" ] (List.map viewSizeRadio [ Small, Medium, Large ])


viewSizeRadio : ThumbnailSize -> Html Msg
viewSizeRadio thumbnailSize =
    label [] [ input [ type_ "radio", name "size", onClick (ClickedSize thumbnailSize) ] [], text (sizeToString thumbnailSize) ]


thumbnails : Model -> Html Msg
thumbnails model =
    div [ id "thumbnails", class (sizeToString model.chosenSize) ] (List.map (viewThumbnail model.selectedUrl) model.photos)


largePhoto model =
    img [ src (urlPrefix ++ "large/" ++ model.selectedUrl), class "large" ] []


surpriseButton : Html Msg
surpriseButton =
    button [ onClick ClickedSurpriseMe ] [ text "Surprise Me!" ]



{- update -}


update msg model =
    case msg of
        ClickedPhoto url ->
            { model | selectedUrl = url }

        ClickedSurpriseMe ->
            { model | selectedUrl = "2.jpeg" }

        ClickedSize thumbnailSize ->
            { model | chosenSize = thumbnailSize }



{- Helper functions -}


sizeToString : ThumbnailSize -> String
sizeToString thumbnailSize =
    case thumbnailSize of
        Large ->
            "large"

        Medium ->
            "med"

        Small ->
            "small"


urlPrefix =
    "https://elm-in-action.com/"


viewThumbnail selectedUrl photo =
    img
        [ src (urlPrefix ++ photo.url)
        , classList [ ( "selected", photo.url == selectedUrl ) ]
        , onClick (ClickedPhoto photo.url)
        ]
        []
