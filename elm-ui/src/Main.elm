module Main exposing (..)

import Browser
import Html exposing (Html, text, div, h1, img, pre, code)
import Html.Attributes exposing (src)
import SyntaxHighlight exposing (useTheme, monokai, elm, toBlockHtml)


---- MODEL ----


type alias Model =
    {code: String}


init : ( Model, Cmd Msg )
init =
    ( {code = ""}, Cmd.none )



---- UPDATE ----


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ useTheme monokai
        , elm model.code
          |> Result.map (toBlockHtml (Just 1))
          |> Result.withDefault
            (pre [] [ code [] [ text model.code ]])
        ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
