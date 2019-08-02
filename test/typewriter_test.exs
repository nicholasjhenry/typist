defmodule TypewriterTest do
  use ExUnit.Case
  doctest Typewriter

  test "greets the world" do
    assert Typewriter.hello() == :world
  end
end
