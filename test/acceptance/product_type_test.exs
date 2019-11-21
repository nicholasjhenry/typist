defmodule Typist.ProductTypeTest do
  use ExUnit.Case
  use Typist

  describe "product type" do
    alias Typist.ProductTypeTest.FirstLast

    deftype FirstLast :: {String.t(), binary}

    test "inline" do
      actual_type = FirstLast.__type__()

      assert match?(%Typist.ProductType{}, actual_type)
      assert :FirstLast == actual_type.name
      assert {"{String.t(), binary}", _} = actual_type.type

      assert %FirstLast{value: {"Jane", "Doe"}}
    end

    defmodule Foo.FirstLast do
      use Typist

      deftype {String.t(), binary}
    end

    test "module" do
      actual_type = Foo.FirstLast.__type__()

      assert match?(%Typist.ProductType{}, actual_type)
      assert :FirstLast == actual_type.name
      assert {"{String.t(), binary}", _} = actual_type.type

      assert %Foo.FirstLast{value: {"Jane", "Doe"}}
    end
  end
end
