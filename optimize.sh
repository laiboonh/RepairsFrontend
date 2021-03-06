#!/bin/sh

set -e

js="build/app.js"
min="build/app.min.js"

elm make src/Main.elm --optimize --output=$js "$@"

uglifyjs $js --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output $min

echo "Compiled size: $(wc -c $js | cut -d ' ' -f 3) bytes ($js)"
echo "Minified size: $(wc -c $min | cut -d ' ' -f 4) bytes ($min)"
echo "Gzipped size:  $(gzip $min -Nc | wc -c | cut -d ' ' -f 4) bytes"