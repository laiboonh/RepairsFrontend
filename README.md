![Github Actions](https://github.com/laiboonh/RepairsFrontend/actions/workflows/ci_cd.yml/badge.svg)
[![Netlify](https://api.netlify.com/api/v1/badges/d49f0e26-f487-47e6-8172-471e94ec7359/deploy-status)](https://app.netlify.com/sites/quirky-shannon-65b4ce/deploys)

# Setup
1. Install elm https://guide.elm-lang.org/install/elm.html
2. Install nodejs https://nodejs.org/en/
3. Try `elm-repl` to see that it works
4. Install elm-format `sudo npm install elm-format -g`
5. Install elm-test `sudo npm install elm-test -g`
6. Install IntelliJ Elm plugin 
7. Under `Preference` setup toolchain for Elm compiler, elm-format and elm-test

# Run
1. Run `elm make src/Main.elm --output=build/app.js` in terminal
2. Open `build/index.hmtl` in browser

# Run Tests
1. `elm-test`

# Development
1. `npx elm-test --watch`
2. To add dependencies `elm install elm/random`

