defmodule Typist.ProductTypeTest do
  use ExUnit.Case
  use Typist

  describe "product type" do
    alias Typist.ProductTypeTest.FirstLast

    deftype FirstLast :: {String.t(), binary}

    test "inline" do
      assert match?(
               %Typist.ProductType{
                 name: :FirstLast,
                 type: {"{String.t(), binary}", _}
               },
               FirstLast.__type__()
             )

      assert %FirstLast{value: {"Jane", "Doe"}}
    end

    defmodule Foo.FirstLast do
      use Typist

      deftype {String.t(), binary}
    end

    test "module" do
      assert match?(
               %Typist.ProductType{
                 name: :FirstLast,
                 type: {"{String.t(), binary}", _}
               },
               Foo.FirstLast.__type__()
             )

      assert %Foo.FirstLast{value: {"Jane", "Doe"}}
    end
  end
end
