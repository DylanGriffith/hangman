import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode


main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }



-- MODEL


type alias Model =
  { guessed : List String
  , word : String
  , sessionId : Maybe String
  }


init : (Model, Cmd Msg)
init =
  ( Model [] "" Nothing
  , getSession
  )



-- UPDATE

type alias Response =
  { sessionId : String
  , word : String
  }

type Msg
  = SessionReceived (Result Http.Error Response)
  | GuessFinished (Result Http.Error Response)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    SessionReceived (Ok response) ->
      ({model | sessionId = Just response.sessionId, word = response.word}, guessLetter response.sessionId)

    GuessFinished (Ok response) ->
      ({model | word = response.word}, guessLetter model.sessionId)

    SessionReceived (Err _) ->
      (model, Cmd.none)


-- VIEW


view : Model -> Html Msg
view model =
  let
    message = case model.sessionId of
      Just sessionId -> sessionId
      Nothing -> "No Session"
  in
    div []
      [ h2 [] [text message]
      , div [] [text model.word]
      ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


-- HTTP


getSession : Cmd Msg
getSession =
  let
    url =
      "http://localhost:4001/api/sessions"
  in
    Http.send SessionReceived (Http.post url (Http.stringBody "application/json" "{\"username\": \"dylan\"}") decodeSession)

guessLetter : String -> Cmd Msg
guessLetter sessionId =
  let
    url =
      "http://localhost:4001/api/sessions/" ++ sessionId ++ "/guess/a"
  in
    Http.send GuessFinished (Http.post url (Http.stringBody "application/json" "{\"username\": \"dylan\"}") decodeSession)


decodeSession : Decode.Decoder Response
decodeSession =
  Decode.map2 Response (Decode.field "session_id" Decode.string) (Decode.field "word" Decode.string)

