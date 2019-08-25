defmodule TypeWriter.ProductTypeTest do
  use ExUnit.Case

  use TypeWriter

  describe "product type" do
    deftype FirstLast1 :: {String.t(), String.t()}

    test "inline defines the meta data" do
      assert FirstLast1.__type__() == %TypeWriter.SingleCaseUnionType{
               name: :FirstLast1,
               type: {{:String, :t, []}, {:String, :t, []}}
             }
    end

    defmodule FirstLast2 do
      use TypeWriter

      deftype {String.t(), String.t()}
    end

    test "module defines the meta data" do
      assert FirstLast2.__type__() == %TypeWriter.SingleCaseUnionType{
               name: :FirstLast2,
               type: {{:String, :t, []}, {:String, :t, []}}
             }
    end
  end
end
