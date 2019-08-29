defmodule Typist.SingleCaseUnionTypeTest do
  use ExUnit.Case
  use Typist

  alias Typist.SingleCaseUnionTypeTest.{
    ProductCode1,
    ProductCode2,
    ProductCode3,
    ProductCode4
  }

  describe "single case union type" do
    deftype ProductCode1 :: String.t()

    test "inline with alias" do
      assert match?(
               %Typist.SingleCaseUnionType{name: :ProductCode1, type: {"String.t()", _}},
               ProductCode1.__type__()
             )

      assert ProductCode1.__spec__() == "@type(t :: %__MODULE__{value: String.t()})"

      assert %ProductCode1{value: "ABC123"}
    end

    deftype ProductCode3 :: binary

    test "inline with basic" do
      assert match?(
               %Typist.SingleCaseUnionType{name: :ProductCode3, type: {"binary", _}},
               ProductCode3.__type__()
             )
    end

    deftype ProductCode4 :: (binary -> integer)

    test "inline with function" do
      assert match?(
               %Typist.SingleCaseUnionType{
                 name: :ProductCode4,
                 type: {"(binary -> integer)", _}
               },
               ProductCode4.__type__()
             )
    end

    defmodule ProductCode2 do
      use Typist

      deftype String.t()
    end

    test "module" do
      assert match?(
               %Typist.SingleCaseUnionType{name: :ProductCode2, type: {"String.t()", _}},
               ProductCode2.__type__()
             )

      assert %ProductCode2{value: "ABC123"}
    end
  end
end
