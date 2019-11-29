defmodule Typist.RecordTypeTest do
  use ExUnit.Case
  use Typist

  describe "defining the type inline" do
    deftype Product do
      code :: String.t()
      price :: integer
    end

    test "defines the type meta-data" do
      metadata = Product.__type__()

      assert metadata.ast ==
               {:record, [], [{:code, {[:String], :t}}, {:price, {:basic, [], [:integer]}}]}

      assert metadata.spec == "@type(t :: %__MODULE__{code: String.t(), price: integer})"
      assert metadata.constructor == "@spec(new(%{code: String.t(), price: integer}) :: t)"
    end

    test "defines a constructor function" do
      assert %Product{code: "ABC", price: 10_00} == Product.new(%{code: "ABC", price: 10_00})
    end
  end

  describe "defining the type in a module" do
    defmodule Foo.Product do
      deftype do
        code :: String.t()
        price :: integer
      end
    end

    test "defines the type meta-data" do
      metadata = Foo.Product.__type__()

      assert metadata.ast ==
               {:record, [], [{:code, {[:String], :t}}, {:price, {:basic, [], [:integer]}}]}

      assert metadata.spec == "@type(t :: %__MODULE__{code: String.t(), price: integer})"
      assert metadata.constructor == "@spec(new(%{code: String.t(), price: integer}) :: t)"
    end

    test "defines a constructor function" do
      assert %Foo.Product{code: "ABC", price: 10_00} ==
               Foo.Product.new(%{code: "ABC", price: 10_00})
    end
  end
end
