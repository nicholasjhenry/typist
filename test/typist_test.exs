defmodule TypistTest do
  use ExUnit.Case
  doctest Typist

  test "greets the world" do
    assert Typist.hello() == :world
  end
end
