defmodule Typist.SingleCaseUnionTypeTest do
  use ExUnit.Case

  use Typist

  defmodule Foo do
    deftype integer
  end

  describe "defining a type in a module" do
    test "defines the type meta-data" do
      metadata = Foo.__type__()

      assert metadata.ast == :integer
    end
  end

  describe "defining a type inline as an alias for an Elixir remote type" do
    deftype Bar :: integer

    test "defines the type meta-data" do
      metadata = Bar.__type__()

      assert metadata.ast == :integer
    end
  end
end
