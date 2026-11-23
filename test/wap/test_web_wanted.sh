#!/usr/bin/env bash
# a program's routes (wiki/html.md "Routes", lib/router.wap), served over HTTP by lib/web.wap and answering a WAGI
# request by lib/wagi.wap: what wap does not build yet, each red line a to-do. Run it with bash test/wap/test_web_wanted.sh
source "$(dirname "$0")/compile.sh"

# the routes of wiki/html.md and a few more, each answer a text
routes='use router
get "/teapot" {
	status 418
	header "X-Wap" "brewed"
	"short and stout"
}
get "/users/:id:int" { "user " + (parameter("id") ?? "none") + (request.query.get("tab") ?? "") }
get "/files/:path*" { parameter("path") ?? "" }
post "/todos" { "got " + (request.form.get("item") ?? request.body) }
get "/data" { {n: 1} }'

printf '%s\nuse web\nserve(0)\n' "$routes" >"$stage/server.wap"
$wap "$compiler" "$stage/server.wap" "$stage/server.wasm" >"$stage/server.out" 2>&1 && { $wap "$stage/server.wasm" >"$stage/server.out" 2>&1 & server=$!; }
for i in $(seq 1 40); do grep -q serving "$stage/server.out" && break; perl -e 'select(undef, undef, undef, 0.25)'; done
port=$(grep -o 'localhost:[0-9]*' "$stage/server.out" | cut -d: -f2)
# what the server answers to curl's request, its status line and headers too with -i, line ends as \n
asked() { [ -n "$port" ] && curl -s "$@" | tr -d '\r' || head -3 "$stage/server.out"; }

check "a route's status, headers and text" "$(asked -i "http://localhost:$port/teapot")" "HTTP/1.1 418 I'm a teapot
Content-Type: text/plain; charset=utf-8
X-Wap: brewed
Content-Length: 15
Connection: close

short and stout"
check "a typed parameter and the query" "$(asked "http://localhost:$port/users/7?tab=x")" "user 7x"
check "a typed parameter takes only its type" "$(asked "http://localhost:$port/users/ann")" "no route answers GET /users/ann"
check "a repeated parameter takes the rest of the path" "$(asked "http://localhost:$port/files/a/b.txt")" "a/b.txt"
check "a form's POST answers by sending the browser back" "$(asked -i -d item=tea -H 'Referer: /list' "http://localhost:$port/todos" | grep -E '^(HTTP|Location)')" "HTTP/1.1 303 See Other
Location: /list"
check "a POST's body" "$(asked -d raw -H 'Content-Type: text/plain' "http://localhost:$port/todos")" "got raw"
check "an answer that is no text is JSON" "$(asked -i "http://localhost:$port/data" | grep -E '^(Content-Type|\{)')" "Content-Type: application/json
{\"n\":1}"
[ -n "${server:-}" ] && kill "$server" && wait "$server" 2>/dev/null

printf '%s\nuse wagi\nroutes_wagi()\n' "$routes" >"$stage/wagi_routes.wap"
wagi() { $wap "$compiler" "$stage/wagi_routes.wap" "$stage/wagi_routes.wasm" 2>&1 && env "$@" $wap "$stage/wagi_routes.wasm" 2>&1; }
check "a WAGI request answered CGI-style" "$(wagi REQUEST_METHOD=GET PATH_INFO=/users/7 QUERY_STRING=tab=%21)" "Status: 200
Content-Type: text/plain; charset=utf-8

user 7!"
exit $((failures > 0))
