defmodule Typist.ProductTypeTest do
  use ExUnit.Case
  use Typist

  describe "defining the type inline" do
    alias Typist.ProductTypeTest.FirstLast

    deftype FirstLast :: {String.t(), binary}

    test "defines the type meta-data" do
      actual_type = FirstLast.__type__()

      assert match?(%Typist.ProductType{}, actual_type)
      assert :FirstLast == actual_type.name
      assert {"{String.t(), binary}", _} = actual_type.type
    end

    test "defines the spec" do
      assert FirstLast.__spec__() == "@type(t :: %__MODULE__{value: {String.t(), binary}})"
    end

    test "can be constructed" do
      assert %FirstLast{value: {"Jane", "Doe"}}
    end
  end

  describe "defining the type in a module" do
    defmodule Foo.FirstLast do
      use Typist

      deftype {String.t(), binary}
    end

    test "defines the type meta-data" do
      actual_type = Foo.FirstLast.__type__()

      assert match?(%Typist.ProductType{}, actual_type)
      assert :FirstLast == actual_type.name
      assert {"{String.t(), binary}", _} = actual_type.type
    end

    test "defines the spec" do
      assert Foo.FirstLast.__spec__() == "@type(t :: %__MODULE__{value: {String.t(), binary}})"
    end

    test "can be constructed" do
      assert %Foo.FirstLast{value: {"Jane", "Doe"}}
    end
  end
end
