module Main exposing (main)

import Html exposing (div, h1, img, text)
import Html.Attributes exposing (id, src)


main =
    view "NA"


view model =
    div [] [ header, thumbnails ]


thumbnails =
    div [ id "thumbnails" ] [ img1, img2, img3 ]


header =
    h1 [] [ text "Photo Groove" ]


img1 =
    img [ src "https://elm-in-action.com/1.jpeg" ] []


img2 =
    img [ src "https://elm-in-action.com/2.jpeg" ] []


img3 =
    img [ src "https://elm-in-action.com/3.jpeg" ] []
