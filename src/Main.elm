module Main exposing (Model, Msg(..), Status(..), ThumbnailSize(..), main, urlPrefix, view)

import Browser
import Html exposing (Html, button, div, figure, footer, header, img, input, label, nav, p, section, text)
import Html.Attributes exposing (checked, class, classList, id, name, placeholder, src, title, type_)
import Html.Events exposing (onClick, onInput)
import Http exposing (Error(..))
import Json.Decode exposing (Decoder, int, list, string, succeed)
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode
import Platform.Sub as Sub
import Random


type Status
    = Loading
    | Loaded (List Photo) (Maybe String)
    | Errored String


type alias Photo =
    { url : String, size : Int, title : String }


type alias Model =
    { status : Status
    , chosenSize : ThumbnailSize
    , showLoginModal : Bool
    , disableButtons : Bool
    , userName : String
    }


type Msg
    = ClickedPhoto String
    | ClickedSize ThumbnailSize
    | ClickedSurpriseMe
    | ClickedLogin
    | ToggleLoginModal
    | GotRandomPhoto Photo
    | GotPhotos (Result Http.Error (List Photo))
    | Username String
    | LoggedIn (Result Http.Error ())


type ThumbnailSize
    = Small
    | Medium
    | Large


initialModel : Model
initialModel =
    { status = Loading
    , chosenSize = Medium
    , showLoginModal = False
    , disableButtons = False
    , userName = ""
    }


initialCommand : Cmd Msg
initialCommand =
    Http.get
        { url = "https://elm-in-action.com/photos/list.json"
        , expect = Http.expectJson GotPhotos (list photoDecoder)
        }


loginCommand : String -> Cmd Msg
loginCommand userName =
    let
        encode =
            Encode.object
                [ ( "id", Encode.string userName )
                ]
    in
    Http.post
        { url = "https://blooming-anchorage-54785.herokuapp.com/login"
        , body = Http.jsonBody encode
        , expect = Http.expectWhatever LoggedIn
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
            div [ class "container is-max-desktop" ] [ head, form model, content model photos maybeSelectedUrl, loginModal model ]

        Errored error ->
            div [ class "container is-max-desktop" ] [ text error ]


head =
    section [ class "hero is-success" ]
        [ div [ class "hero-body" ] [ p [ class "title" ] [ text "Photo Booth" ] ] ]


form model =
    section [ class "section" ]
        [ nav [ class "level" ]
            [ div [ class "level-left" ] [ div [ class "level-item" ] [ viewSizeChooser model.chosenSize ] ]
            , div [ class "level-right" ] [ div [ class "level-item" ] [ surpriseButton ], div [ class "level-item" ] [ loginButton ] ]
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


loginButton : Html Msg
loginButton =
    button [ onClick ToggleLoginModal, class "button is-link" ] [ text "Login" ]


loginModal : Model -> Html Msg
loginModal model =
    div [ classList [ ( "modal", True ), ( "is-active", model.showLoginModal ) ] ]
        [ div [ class "modal-background" ] []
        , div [ class "modal-card" ]
            [ header
                [ class "modal-card-head" ]
                [ p [ class "modal-card-title" ] [ text "Login" ], button [ onClick ToggleLoginModal, class "delete" ] [] ]
            , section [ class "modal-card-body" ]
                [ div [ class "field" ]
                    [ label [ class "label" ] [ text "Username" ]
                    , div [ class "control" ]
                        [ input [ onInput Username, class "input", type_ "text", placeholder "fec298ac-28ed-4144-914c-bc06816015bf" ] []
                        ]
                    ]
                ]
            , footer [ class "modal-card-foot" ]
                [ button [ onClick ClickedLogin, classList [ ( "button is-success", True ), ( "is-loading", model.disableButtons ) ] ] [ text "Go!" ]
                , button [ onClick ToggleLoginModal, class "button" ] [ text "Cancel" ]
                ]
            ]
        ]



{- update -}


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Username x ->
            ( { model | userName = x }, Cmd.none )

        ClickedPhoto url ->
            ( { model | status = updateSelectedUrl model.status (Just url) }, Cmd.none )

        ToggleLoginModal ->
            ( { model | showLoginModal = not model.showLoginModal }, Cmd.none )

        ClickedLogin ->
            ( { model | disableButtons = True }, loginCommand model.userName )

        LoggedIn (Ok ()) ->
            ( { model | disableButtons = False }, Cmd.none )

        LoggedIn (Err httpError) ->
            ( { model | disableButtons = False }, Cmd.none )

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
