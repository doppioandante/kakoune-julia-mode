#!/bin/sh

rm -f in out
mkfifo in out
( julia repl.jl in out
)>log.txt 2>&1 </dev/null &

echo "$@" > in
cat out
echo "quit" > in
rm in out
