defmodule TypeWriter.ProductTypeTest do
  use ExUnit.Case

  use TypeWriter

  describe "product type" do
    deftype FirstLast1 :: {String.t(), binary}

    test "inline" do
      assert match?(
               %TypeWriter.SingleCaseUnionType{
                 name: :FirstLast1,
                 type: {"{String.t(), binary}", _}
               },
               FirstLast1.__type__()
             )
    end

    defmodule FirstLast2 do
      use TypeWriter

      deftype {String.t(), binary}
    end

    test "module" do
      assert match?(
               %TypeWriter.SingleCaseUnionType{
                 name: :FirstLast2,
                 type: {"{String.t(), binary}", _}
               },
               FirstLast2.__type__()
             )
    end
  end
end
