# servant-reflex

[![Build Status](https://travis-ci.org/imalsogreg/servant-reflex.svg?branch=master)](https://travis-ci.org/imalsogreg/servant-reflex)

## The problem `servant-reflex` solves

Keeping your frontend in sync with your API server can be difficult - when the API changes its input parameters or return type, XHR requests from the frontend will fail at runtime. If your API is defined by [servant](haskell-servant.readthedocs.io) combinators, you can use `servant-reflex` to share the API between the server and frontend. 
Syncronization between is checked at compile time, and rather than building XHR requests by hand, API endpoints are available behind `reflex`'s FRP semantics.



## Example

We have a webservice API defined in a module where both the server (compiled with ghc) and the frontend (compiled with ghcjs) can see it:

```haskell
type API = "getint"  :> Get '[JSON] Int
      :<|> "sayhi"   :> QueryParam  "username" Text
                     :> QueryParams "greetings" Text
                     :> QueryFlag   "gusto"
                     :> Get '[JSON] Text
      :<|> "double" :> ReqBody '[JSON] Double
                    :> Post '[JSON] Double
      :<|> Raw
```

`servant-reflex` then computes client functions that can query the API through an `XhrRequest`.

```haskell

 runGUI :: forall t m.MonadWidget t m => do

  -- servant-reflex computes FRP functions for each API endpoint
  let (getint :<|> sayhi :<|> doubleit :<|> _) = client (Proxy :: Proxy API)
                                                        (Proxy :: Proxy m)
                                                        (constDyn (BasePath "/"))
```

These client functions are computed from your API type. They manage serialization, XhrRequest generation, and deserialization for you. `a` parameters used in URL captures become `Dynamic t (Either Text a)` parameters in the client functions. 'QueryFlag', 'QueryParams' and 'QueryParam' API parameters map to 'Dynamic t Bool', 'Dynamic t [a]' and 'Dynamic t (QParam a)' respectively. These parameters to the client function are wrapped with failure possibility to allow you to indicate at any time whether input validation for that parameter has failed and no valid XHR request can be generated. The final parameter is a trigger event for the XHR request. The return value `Event t (ReqResult a)` contains responses from the API server.

```haskell
   -- No need to write these functions. servant-reflex creates them for you!
   getint :: MonadWidget t m
          => Event t ()  -- ^ Trigger the XHR Request
          -> m (Event t (ReqResult Int)) -- ^ Consume the answer

   sayhi :: MonadWidget t m
         => Dynamic t (QParam Text) 
            -- ^ One input parameter - the 'name', wrapped in 'QParam'
         -> Dynamic t [Text]
            -- ^ Another input: list of preferred greetings
         -> Dynamic t Bool
            -- ^ Flag for capitalizing the response
         -> Event t ()
            -- ^ Trigger the XHR Request
         -> m (Event t (ReqResult Text))

   doubleit :: MonadWidget t m
            => Dynamic t (Either Text Double)
            -> Event t ()
            -> m (Event t (ReqResult Double))
```

`ReqResult a` is defined in [`Servant.Common.Req`](https://github.com/imalsogreg/servant-reflex/blob/6d866e338edb9bf6fd8f8d5083ff0187b4d8c0d2/src/Servant/Common/Req.hs#L40-L42) and reports whether or not your request was sent (if validation fails, the request won't be sent), and how decoding of the response went. You can pattern match on these explicitly, but usually you'll want to use `fmapMaybe :: (a -> Maybe b) -> Event t a -> Event t b` and one of the elimination functions to filter the result type you care about, like this:

```haskell
  -- ... continued ...
  res :: Event t (ReqResult Double) <- doubleIt xs triggers
  let ys   = fmapMaybe reqSuccess res
      errs = fmapMaybe reqFailure res
  
  -- Green <p> tag showing the last good result 
  elAttr "p" ("style" =: "color:green") $ do
    text "Last good result: "
    dynText =<< holdDyn "" (fmap show ys)
    
  -- Red <p> tag showing the last error, cleared by a new good value
  elAttr "p" ("style" =: "color:red") $
    dynText =<< holdDyn "" (leftmost [errs, const "" <$> ys])
```

This example builds some input fields to enter API parameters, buttons to trigger the API calls, and text elements to show the results:

```haskell
  elClass "div" "int-demo" $ do
    intButton  <- button "Get Int"
    serverInts <- fmapMaybe resSuccess <$> getint intButton
    display =<< holdDyn (Just 0) serverInts

  elClass "div" "hello-demo" $ do
    nameText <- QParamSome . value <$> textInput def
    greetings <- (fmap words . value) <$> textInput def
    withGusto <- checkbox def
    helloButton <- button "Say hi"
    hellos <- fmapMaybe resResult <$> sayhi nameText greetings withGusto helloButton
    display =<< holdDyn Nothing hellos

  elClass "div" "demo-double" $ do
    inputDouble  <- (fmapMaybe readMaybe) <$> textInput def
    doubleButton <- button "Double it"
    outputDouble <- fmapMaybe resSuccess <$> doubleit inputDouble doubleButton
    display =<< holdDyn Nothing outputDouble
```

For a great introduction to recative DOM building, see the [README](https://github.com/reflex-frp/reflex-platform) for the `reflex-platform`. For more information about servant, see their [documentation](http://haskell-servant.readthedocs.io/en/stable/). Thanks to the respective authors of these fabulous libraries.


## Building the library and test server

This repository comes with a small example of an API shared between a ghcjs-compiled frontend ([exec/](https://github.com/imalsogreg/servant-reflex/tree/master/exec)) and a ghc-compiled backend ([testserver/](https://github.com/imalsogreg/servant-reflex/tree/master/testserver). To build these components:


First build the library:

```
git clone https://github.com/reflex-frp/reflex-platform
git submodule update --init --recursive
./build.sh
```

Then build the test server:

```
deps/reflex-platform/work-on ./overrides-ghc.nix ./testserver --command "cd testserver && cabal build"
```


## Running the example site

The server must be run from the directory where static assets live:

```
cd testserver
dist/build/back/back -p 8001
```

And simply browse to `localhost:8001`

**For a larger example of a project that shares types between backend and frontend, see [hsnippet](https://github.com/mightybyte/hsnippet).**
