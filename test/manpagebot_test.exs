defmodule ManpagebotTest do
  use ExUnit.Case
  doctest Manpagebot

  test "greets the world" do
    assert Manpagebot.hello() == :world
  end
end
