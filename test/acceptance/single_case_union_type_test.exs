defmodule TypeWriter.SingleCaseUnionTypeTest do
  use ExUnit.Case

  use TypeWriter

  describe "single case union type" do
    deftype ProductCode1 :: String.t()

    test "inline with alias" do
      assert match?(
               %TypeWriter.SingleCaseUnionType{name: :ProductCode1, type: {"String.t()", _}},
               ProductCode1.__type__()
             )

      assert %ProductCode1{value: "ABC123"}
    end

    deftype ProductCode3 :: binary

    test "inline with basic" do
      assert match?(
               %TypeWriter.SingleCaseUnionType{name: :ProductCode3, type: {"binary", _}},
               ProductCode3.__type__()
             )
    end

    deftype ProductCode4 :: (a -> b)

    test "inline with function" do
      assert match?(
               %TypeWriter.SingleCaseUnionType{name: :ProductCode4, type: {"(a -> b)", _}},
               ProductCode4.__type__()
             )
    end

    defmodule ProductCode2 do
      use TypeWriter

      deftype String.t()
    end

    test "module" do
      assert match?(
               %TypeWriter.SingleCaseUnionType{name: :ProductCode2, type: {"String.t()", _}},
               ProductCode2.__type__()
             )

      assert %ProductCode2{value: "ABC123"}
    end
  end
end
