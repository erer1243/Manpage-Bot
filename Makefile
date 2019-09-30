.PHONY: all run

all:
	BOT_TOKEN=`cat BOT_TOKEN` mix

run:
	BOT_TOKEN=`cat BOT_TOKEN` mix run --no-halt
