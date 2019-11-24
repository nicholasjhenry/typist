defmodule Typist.SingleCaseUnionTypeTest do
  use ExUnit.Case
  use Typist

  deftype ProductCodeFoo :: String.t()

  describe "defining a type inline as an alias for an Elixir remote type" do
    test "defines the type meta-data" do
      actual_type = ProductCodeFoo.__type__()

      assert match?(%Typist.SingleCaseUnionType{}, actual_type)
      assert :ProductCodeFoo == actual_type.name
      assert actual_type.spec == "@type(t :: %__MODULE__{value: String.t()})"
    end

    test "defines a constructor function" do
      assert %ProductCodeFoo{value: "ABC123"} == ProductCodeFoo.new("ABC123")
    end
  end

  describe "defining a type inline as an alias for a basic type" do
    deftype ProductCodeBar :: binary

    test "defines the type meta-data" do
      actual_type = ProductCodeBar.__type__()

      assert match?(%Typist.SingleCaseUnionType{}, actual_type)
      assert :ProductCodeBar == actual_type.name
      assert actual_type.spec == "@type(t :: %__MODULE__{value: binary})"
    end

    test "defines a constructor function" do
      assert %ProductCodeBar{value: "ABC123"} == ProductCodeBar.new("ABC123")
    end
  end

  describe "defining a type inline for a function" do
    deftype ProductCodeBaz :: (binary -> integer)

    test "defines the type meta-data" do
      actual_type = ProductCodeBaz.__type__()

      assert match?(%Typist.SingleCaseUnionType{}, actual_type)
      assert :ProductCodeBaz == actual_type.name
      assert actual_type.spec == "@type(t :: %__MODULE__{value: (binary -> integer)})"
    end

    test "defines a constructor function" do
      assert %ProductCodeBaz{value: _} = ProductCodeBaz.new(fn _string -> 123 end)
    end
  end

  describe "defining a type in a module" do
    defmodule ProductCodeQux do
      use Typist

      deftype String.t()
    end

    test "defines the type meta-data" do
      actual_type = ProductCodeQux.__type__()

      assert match?(%Typist.SingleCaseUnionType{}, actual_type)
      assert :ProductCodeQux == actual_type.name
      assert actual_type.spec == "@type(t :: %__MODULE__{value: String.t()})"
    end

    test "defines a constructor function" do
      assert %ProductCodeQux{value: "ABC123"} == ProductCodeQux.new("ABC123")
    end
  end

  describe "unwrapping" do
    test "returns the wrapped value" do
      product_code = ProductCodeFoo.new("ABC123")
      assert "ABC123" == ProductCodeFoo.value(product_code)
    end
  end

  describe "applying" do
    test "applies the function to the unwrapped value" do
      product_code = ProductCodeFoo.new("ABC123")
      func = fn value -> "value is #{value}" end
      assert "value is ABC123" == ProductCodeFoo.apply(product_code, func)
    end
  end

  describe "definig a remote alias for a remote type" do
    deftype EmailOnly.t() :: EmailContactInfo.t()

    test "defines the remote alias" do
      actual_type = EmailOnly.__type__()
      assert actual_type.spec == "@type(t :: %__MODULE__{value: EmailContactInfo.t()})"
    end
  end
end
