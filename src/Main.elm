module Main exposing (Msg(..), initialModel, main, urlPrefix, view)

import Array exposing (Array, fromList)
import Browser
import Html exposing (Html, button, div, h1, h3, img, input, label, text)
import Html.Attributes exposing (class, classList, id, name, src, type_)
import Html.Events exposing (onClick)
import Platform.Sub as Sub
import Random


type alias Photo =
    { url : String }


type alias Model =
    { photos : List Photo, selectedUrl : String, chosenSize : ThumbnailSize }


type Msg
    = ClickedPhoto String
    | ClickedSize ThumbnailSize
    | ClickedSurpriseMe
    | GotSelectedIndex Int


type ThumbnailSize
    = Small
    | Medium
    | Large


initialModel : Model
initialModel =
    { photos = [ { url = "1.jpeg" }, { url = "2.jpeg" }, { url = "3.jpeg" } ], selectedUrl = "1.jpeg", chosenSize = Medium }


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( initialModel, Cmd.none )
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedPhoto url ->
            ( { model | selectedUrl = url }, Cmd.none )

        ClickedSurpriseMe ->
            ( model, Random.generate GotSelectedIndex (randomPhotoPicker model.photos) )

        ClickedSize thumbnailSize ->
            ( { model | chosenSize = thumbnailSize }, Cmd.none )

        GotSelectedIndex index ->
            ( { model | selectedUrl = getPhotoUrl model.photos index }, Cmd.none )



{- Helper functions -}


getPhotoUrl : List Photo -> Int -> String
getPhotoUrl photos index =
    case Array.get index (fromList photos) of
        Just photo ->
            photo.url

        Nothing ->
            ""


randomPhotoPicker : List Photo -> Random.Generator Int
randomPhotoPicker photos =
    Random.int 0 (List.length photos - 1)


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
