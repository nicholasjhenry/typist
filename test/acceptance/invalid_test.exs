defmodule Typist.InvalidTest do
  use ExUnit.Case
  use Typist

  test "invalid type definition raises an exception" do
    invalid_ast =
      quote do
        deftype name :: Wrong.t()
      end

    assert_raise Typist.InvalidTypeDefinition, fn ->
      Typist.maybe_build(__MODULE__, invalid_ast, :none)
    end
  end
end
