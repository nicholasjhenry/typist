defmodule Typist.SingleCaseUnionTypeTest do
  use ExUnit.Case
  use Typist

  describe "defining a type inline as an alias for an Elixir remote type" do
    alias Typist.SingleCaseUnionTypeTest.ProductCodeFoo
    deftype ProductCodeFoo :: String.t()

    test "defines the type meta-data" do
      actual_type = ProductCodeFoo.__type__()

      assert match?(%Typist.SingleCaseUnionType{}, actual_type)
      assert :ProductCodeFoo == actual_type.name
      assert {"String.t()", _} = actual_type.type
    end

    test "defines the spec" do
      assert ProductCodeFoo.__spec__() == "@type(t :: %__MODULE__{value: String.t()})"
    end

    test "defines a constructor function" do
      assert %ProductCodeFoo{value: "ABC123"} == ProductCodeFoo.new("ABC123")
    end
  end

  describe "defining a type inline as an alias for a basic type" do
    alias Typist.SingleCaseUnionTypeTest.ProductCodeBar
    deftype ProductCodeBar :: binary

    test "defines the type meta-data" do
      actual_type = ProductCodeBar.__type__()

      assert match?(%Typist.SingleCaseUnionType{}, actual_type)
      assert :ProductCodeBar == actual_type.name
      assert {"binary", _} = actual_type.type
    end

    test "defines the spec" do
      assert ProductCodeBar.__spec__() == "@type(t :: %__MODULE__{value: binary})"
    end

    test "defines a constructor function" do
      assert %ProductCodeBar{value: "ABC123"} == ProductCodeBar.new("ABC123")
    end
  end

  describe "defining a type inline for a function" do
    alias Typist.SingleCaseUnionTypeTest.ProductCodeBaz
    deftype ProductCodeBaz :: (binary -> integer)

    test "defines the type meta-data" do
      actual_type = ProductCodeBaz.__type__()

      assert match?(%Typist.SingleCaseUnionType{}, actual_type)
      assert :ProductCodeBaz == actual_type.name
      assert {"(binary -> integer)", _} = actual_type.type
    end

    test "defines the spec" do
      assert ProductCodeBaz.__spec__() == "@type(t :: %__MODULE__{value: (binary -> integer)})"
    end

    test "defines a constructor function" do
      assert %ProductCodeBaz{value: _} = ProductCodeBaz.new(fn _string -> 123 end)
    end
  end

  describe "defining a type in a module" do
    alias Typist.SingleCaseUnionTypeTest.ProductCodeQux

    defmodule ProductCodeQux do
      use Typist

      deftype String.t()
    end

    test "defines the type meta-data" do
      actual_type = ProductCodeQux.__type__()

      assert match?(%Typist.SingleCaseUnionType{}, actual_type)
      assert :ProductCodeQux == actual_type.name
      assert {"String.t()", _} = actual_type.type
    end

    test "defines a constructor function" do
      assert %ProductCodeQux{value: "ABC123"} == ProductCodeQux.new("ABC123")
    end
  end
end
