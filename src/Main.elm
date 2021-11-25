module Main exposing (Model, Msg(..), Status(..), ThumbnailSize(..), main, urlPrefix, view)

import Browser
import Html exposing (Html, button, div, figure, img, input, label, nav, p, section, text)
import Html.Attributes exposing (checked, class, classList, id, name, src, title, type_)
import Html.Events exposing (onClick)
import Http exposing (Error(..))
import Json.Decode exposing (Decoder, int, list, string, succeed)
import Json.Decode.Pipeline exposing (optional, required)
import Platform.Sub as Sub
import Random


type Status
    = Loading
    | Loaded (List Photo) (Maybe String)
    | Errored String


type alias Photo =
    { url : String, size : Int, title : String }


type alias Model =
    { status : Status, chosenSize : ThumbnailSize }


type Msg
    = ClickedPhoto String
    | ClickedSize ThumbnailSize
    | ClickedSurpriseMe
    | GotRandomPhoto Photo
    | GotPhotos (Result Http.Error (List Photo))


type ThumbnailSize
    = Small
    | Medium
    | Large


initialModel : Model
initialModel =
    { status = Loading, chosenSize = Medium }


initialCommand : Cmd Msg
initialCommand =
    Http.get
        { url = "https://elm-in-action.com/photos/list.json"
        , expect = Http.expectJson GotPhotos (list photoDecoder)
        }


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( initialModel, initialCommand )
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


view : Model -> Html Msg
view model =
    case model.status of
        Loading ->
            div [ class "container is-max-desktop" ] [ text "Loading..." ]

        Loaded photos maybeSelectedUrl ->
            div [ class "container is-max-desktop" ] [ header, form model, content model photos maybeSelectedUrl ]

        Errored error ->
            div [ class "container is-max-desktop" ] [ text error ]


header =
    section [ class "hero is-success" ]
        [ div [ class "hero-body" ] [ p [ class "title" ] [ text "Photo Booth" ] ] ]


form model =
    section [ class "section" ]
        [ nav [ class "level" ]
            [ div [ class "level-left" ] [ div [ class "level-item" ] [ viewSizeChooser model.chosenSize ] ]
            , div [ class "level-right" ] [ div [ class "level-item" ] [ surpriseButton ] ]
            ]
        ]


content model photos maybeSelectedUrl =
    div [ class "tile is-ancestor is-vertical" ]
        [ div [ class "tile is-child" ] [ thumbnails photos maybeSelectedUrl model.chosenSize ]
        , div [ class "tile is-child" ] [ div [ class "container" ] [ largePhoto maybeSelectedUrl ] ]
        ]


viewSizeChooserTitle =
    label [ class "label" ] [ text "Thumbnail Size" ]


viewSizeChooser chosenSize =
    div [ class "field" ]
        [ viewSizeChooserTitle
        , div
            [ id "choose-size", class "control" ]
            (List.map (viewSizeRadio chosenSize) [ Small, Medium, Large ])
        ]


viewSizeRadio : ThumbnailSize -> ThumbnailSize -> Html Msg
viewSizeRadio chosenSize thumbnailSize =
    label [ class "radio" ] [ input [ type_ "radio", name "size", onClick (ClickedSize thumbnailSize), checked (chosenSize == thumbnailSize), class "radio" ] [], text (sizeToString thumbnailSize) ]


thumbnails : List Photo -> Maybe String -> ThumbnailSize -> Html Msg
thumbnails photos maybeSelectedUrl chosenSize =
    section [ class "section" ]
        [ nav [ class "level" ]
            [ div [ class "level-left" ]
                [ div [ class "level-item" ] (List.map (viewThumbnail maybeSelectedUrl chosenSize) photos)
                ]
            ]
        ]


largePhoto : Maybe String -> Html Msg
largePhoto maybeSelectedUrl =
    let
        image =
            case maybeSelectedUrl of
                Just url ->
                    img [ src (urlPrefix ++ "large/" ++ url), class "large" ] []

                Nothing ->
                    img [ class "large" ] []
    in
    section [ class "section" ] [ image ]


surpriseButton : Html Msg
surpriseButton =
    button [ onClick ClickedSurpriseMe, class "button is-link" ] [ text "Surprise Me!" ]



{- update -}


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedPhoto url ->
            ( { model | status = updateSelectedUrl model.status (Just url) }, Cmd.none )

        ClickedSurpriseMe ->
            case model.status of
                Loaded (firstPhoto :: otherPhotos) _ ->
                    ( model
                    , Random.generate GotRandomPhoto
                        (Random.uniform firstPhoto otherPhotos)
                    )

                Loaded [] _ ->
                    ( model, Cmd.none )

                Loading ->
                    ( model, Cmd.none )

                Errored _ ->
                    ( model, Cmd.none )

        ClickedSize thumbnailSize ->
            ( { model | chosenSize = thumbnailSize }, Cmd.none )

        GotRandomPhoto photo ->
            ( { model | status = updateSelectedUrl model.status (Just photo.url) }, Cmd.none )

        GotPhotos (Ok photos) ->
            ( { model | status = Loaded photos (defaultSelected photos) }, Cmd.none )

        GotPhotos (Err httpError) ->
            ( { model | status = Errored (errorToString httpError) }, Cmd.none )



{- Helper functions -}


photoDecoder : Decoder Photo
photoDecoder =
    succeed Photo
        |> required "url" string
        |> required "size" int
        |> optional "title" string "(undefined)"


updateSelectedUrl : Status -> Maybe String -> Status
updateSelectedUrl status maybeSelectedUrl =
    case status of
        Loaded photos _ ->
            Loaded photos maybeSelectedUrl

        Loading ->
            status

        Errored _ ->
            status


defaultSelected : List Photo -> Maybe String
defaultSelected photos =
    List.head photos |> Maybe.map (\photo -> photo.url)


errorToString : Http.Error -> String
errorToString error =
    case error of
        BadUrl url ->
            "The URL " ++ url ++ " was invalid"

        Timeout ->
            "Unable to reach the server, try again"

        NetworkError ->
            "Unable to reach the server, check your network connection"

        BadStatus 500 ->
            "The server had a problem, try again later"

        BadStatus 400 ->
            "Verify your information and try again"

        BadStatus x ->
            "Unknown error " ++ String.fromInt x

        BadBody errorMessage ->
            errorMessage


sizeToClass : ThumbnailSize -> String
sizeToClass thumbnailSize =
    case thumbnailSize of
        Large ->
            "image is-128x128"

        Medium ->
            "image is-96x96"

        Small ->
            "image is-64x64"


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


viewThumbnail : Maybe String -> ThumbnailSize -> Photo -> Html Msg
viewThumbnail maybeSelectedUrl chosenSize photo =
    let
        classes =
            case maybeSelectedUrl of
                Just url ->
                    classList [ ( "selected", photo.url == url ) ]

                Nothing ->
                    classList []
    in
    div [ class "level-item" ]
        [ figure [ class (sizeToClass chosenSize) ]
            [ img
                [ src (urlPrefix ++ photo.url)
                , classes
                , onClick (ClickedPhoto photo.url)
                , title (photo.title ++ " [" ++ String.fromInt photo.size ++ " KB]")
                ]
                []
            ]
        ]
