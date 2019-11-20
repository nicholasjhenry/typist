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
      assert match?(
               %Typist.SingleCaseUnionType{name: :ProductCodeFoo, type: {"String.t()", _}},
               ProductCodeFoo.__type__()
             )

      assert ProductCodeFoo.__spec__() == "@type(t :: %__MODULE__{value: String.t()})"

      assert %ProductCodeFoo{value: "ABC123"}
    end

    deftype ProductCodeBar :: binary

    test "inline with basic" do
      assert match?(
               %Typist.SingleCaseUnionType{name: :ProductCodeBar, type: {"binary", _}},
               ProductCodeBar.__type__()
             )
    end

    deftype ProductCodeBaz :: (binary -> integer)

    test "inline with function" do
      assert match?(
               %Typist.SingleCaseUnionType{
                 name: :ProductCodeBaz,
                 type: {"(binary -> integer)", _}
               },
               ProductCodeBaz.__type__()
             )
    end

    defmodule ProductCodeQux do
      use Typist

      deftype String.t()
    end

    test "module" do
      assert match?(
               %Typist.SingleCaseUnionType{name: :ProductCodeQux, type: {"String.t()", _}},
               ProductCodeQux.__type__()
             )

      assert %ProductCodeQux{value: "ABC123"}
    end
  end
end
