module Main exposing (Model, Msg(..), Status(..), ThumbnailSize(..), main, urlPrefix, view)

import Browser
import Html exposing (Html, button, div, h1, h3, img, input, label, text)
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
            div [ class "content" ] [ header ]

        Loaded photos maybeSelectedUrl ->
            div [ class "content" ] [ header, viewSizeChooserTitle, viewSizeChooser model.chosenSize, surpriseButton, thumbnails photos maybeSelectedUrl model.chosenSize, largePhoto maybeSelectedUrl ]

        Errored error ->
            div [ class "content" ] [ text error ]


header =
    h1 [] [ text "Photo Booth" ]


viewSizeChooserTitle =
    h3 [] [ text "Thumbnail Size" ]


viewSizeChooser chosenSize =
    div [ id "choose-size" ] (List.map (viewSizeRadio chosenSize) [ Small, Medium, Large ])


viewSizeRadio : ThumbnailSize -> ThumbnailSize -> Html Msg
viewSizeRadio chosenSize thumbnailSize =
    label [] [ input [ type_ "radio", name "size", onClick (ClickedSize thumbnailSize), checked (chosenSize == thumbnailSize) ] [], text (sizeToString thumbnailSize) ]


thumbnails : List Photo -> Maybe String -> ThumbnailSize -> Html Msg
thumbnails photos maybeSelectedUrl chosenSize =
    div [ id "thumbnails", class (sizeToString chosenSize) ] (List.map (viewThumbnail maybeSelectedUrl) photos)


largePhoto : Maybe String -> Html Msg
largePhoto maybeSelectedUrl =
    case maybeSelectedUrl of
        Just url ->
            img [ src (urlPrefix ++ "large/" ++ url), class "large" ] []

        Nothing ->
            img [ class "large" ] []


surpriseButton : Html Msg
surpriseButton =
    button [ onClick ClickedSurpriseMe ] [ text "Surprise Me!" ]



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


viewThumbnail : Maybe String -> Photo -> Html Msg
viewThumbnail maybeSelectedUrl photo =
    let
        classes =
            case maybeSelectedUrl of
                Just url ->
                    classList [ ( "selected", photo.url == url ) ]

                Nothing ->
                    classList []
    in
    img
        [ src (urlPrefix ++ photo.url)
        , classes
        , onClick (ClickedPhoto photo.url)
        , title (photo.title ++ " [" ++ String.fromInt photo.size ++ " KB]")
        ]
        []
