defmodule Typist.ProductTypeTest do
  use ExUnit.Case
  use Typist

  describe "defining the type inline" do
    deftype FirstLast :: {String.t(), binary}

    test "defines the type meta-data" do
      actual_type = FirstLast.__type__()

      assert match?(%Typist.ProductType{}, actual_type)
      assert :FirstLast == actual_type.name
      assert actual_type.spec == "@type(t :: %__MODULE__{value: {String.t(), binary}})"
    end

    test "defines a constructor function" do
      assert %FirstLast{value: {"Jane", "Doe"}} == FirstLast.new({"Jane", "Doe"})
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
      assert actual_type.spec == "@type(t :: %__MODULE__{value: {String.t(), binary}})"
    end

    test "defines a constructor function" do
      assert %Foo.FirstLast{value: {"Jane", "Doe"}} == Foo.FirstLast.new({"Jane", "Doe"})
    end
  end
end
