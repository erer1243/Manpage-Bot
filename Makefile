.PHONY: all run format repl test

all:
	BOT_TOKEN=`cat BOT_TOKEN` mix

run:
	BOT_TOKEN=`cat BOT_TOKEN` mix run --no-halt

format:
	mix format

repl:
	BOT_TOKEN=`cat BOT_TOKEN` iex -S mix

test:
	BOT_TOKEN=`cat BOT_TOKEN` mix test
