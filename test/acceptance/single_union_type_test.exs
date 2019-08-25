defmodule TypeWriter.SingleUnionTypeTest do
  use ExUnit.Case

  use TypeWriter

  describe "single case union type" do
    deftype ProductCode1 :: String.t()

    test "inline" do
      assert ProductCode1.__type__() == %TypeWriter.SingleCaseUnionType{
               name: :ProductCode1,
               type: {:String, :t, []}
             }
    end

    defmodule ProductCode2 do
      use TypeWriter

      deftype String.t()
    end

    test "module" do
      assert ProductCode2.__type__() == %TypeWriter.SingleCaseUnionType{
               name: :ProductCode2,
               type: {:String, :t, []}
             }
    end
  end
end
