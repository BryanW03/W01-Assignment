#!/usr/bin/env bash
# Starts the API, sends GET / POST / PUT / DELETE and saves the real
# requests, responses and status codes in evidence.txt
# Needs: .NET 8 SDK and curl.   Run from this folder:  bash run-evidence.sh

set -e
URL="http://localhost:5100"
OUT="evidence.txt"
: > "$OUT"

(cd PizzaApi && dotnet run --urls "$URL" > ../api.log 2>&1) &
sleep 1

# wait until the API answers (max ~60 sec)
for i in $(seq 1 60); do
  if curl -s -o /dev/null "$URL/pizza"; then break; fi
  sleep 1
done

call () {
  local title="$1"; shift
  {
    echo "=================================================="
    echo "$title"
    echo "REQUEST : curl $*"
    echo "--------------------------------------------------"
    curl -s -i "$@"
    echo
    echo
  } >> "$OUT"
}

call "1) GET all pizzas (seed data + my extra pizza)"  "$URL/pizza"
call "2) GET one pizza by id"                          "$URL/pizza/3"
call "3) POST a new pizza"   -X POST "$URL/pizza" -H "Content-Type: application/json" -d '{"name":"Hawaiian","isGlutenFree":false}'
call "4) PUT update pizza 2" -X PUT  "$URL/pizza/2" -H "Content-Type: application/json" -d '{"id":2,"name":"Veggie Deluxe","isGlutenFree":true}'
call "5) DELETE pizza 1"     -X DELETE "$URL/pizza/1"
call "6) GET all pizzas after the changes"             "$URL/pizza"

# stop the API
pkill -f "PizzaApi.dll" 2>/dev/null || true
pkill -f "dotnet run --urls $URL" 2>/dev/null || true

echo "Done. Open evidence.txt and copy it into NOTES.md"
