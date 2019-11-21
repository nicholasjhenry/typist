defmodule Typist.SingleCaseUnionTypeTest do
  use ExUnit.Case
  use Typist

  describe "single case union type" do
    alias Typist.SingleCaseUnionTypeTest.{
      ProductCodeFoo,
      ProductCodeBar,
      ProductCodeBaz,
      ProductCodeQux
    }

    deftype ProductCodeFoo :: String.t()

    test "inline with alias" do
      actual_type = ProductCodeFoo.__type__()

      assert match?(%Typist.SingleCaseUnionType{}, actual_type)
      assert :ProductCodeFoo == actual_type.name
      assert {"String.t()", _} = actual_type.type

      assert ProductCodeFoo.__spec__() == "@type(t :: %__MODULE__{value: String.t()})"

      assert %ProductCodeFoo{value: "ABC123"}
    end

    deftype ProductCodeBar :: binary

    test "inline with basic" do
      actual_type = ProductCodeBar.__type__()

      assert match?(%Typist.SingleCaseUnionType{}, actual_type)
      assert :ProductCodeBar == actual_type.name
      assert {"binary", _} = actual_type.type
    end

    deftype ProductCodeBaz :: (binary -> integer)

    test "inline with function" do
      actual_type = ProductCodeBaz.__type__()

      assert match?(%Typist.SingleCaseUnionType{}, actual_type)
      assert :ProductCodeBaz == actual_type.name
      assert {"(binary -> integer)", _} = actual_type.type

      assert %ProductCodeBaz{value: fn _string -> 123 end}
    end

    defmodule ProductCodeQux do
      use Typist

      deftype String.t()
    end

    test "module" do
      actual_type = ProductCodeQux.__type__()

      assert match?(%Typist.SingleCaseUnionType{}, actual_type)
      assert :ProductCodeQux == actual_type.name
      assert {"String.t()", _} = actual_type.type

      assert %ProductCodeQux{value: "ABC123"}
    end
  end
end
