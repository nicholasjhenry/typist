defmodule TypeWriterTest do
  use ExUnit.Case

  use TypeWriter

  describe "defining a single case union type" do
    deftype ProductCode1 :: String.t()

    test "using inline syntax generates the struct" do
      alias TypeWriterTest.ProductCode1

      assert ProductCode1.__struct__() == %ProductCode1{value: nil}
    end

    defmodule ProductCode2 do
      use TypeWriter

      deftype String.t()
    end

    test "using module syntax generates the struct" do
      assert ProductCode2.__struct__() == %ProductCode2{value: nil}
    end
  end

  deftype Product1 do
    code :: ProductCode1.t()
    price :: float()
  end

  describe "defining a record" do
    test "using inline syntax generates the struct" do
      alias TypeWriterTest.Product1

      assert Product1.__struct__() == %Product1{code: nil, price: nil}
    end

    defmodule Product2 do
      use TypeWriter

      deftype do
        code :: ProductCode1.t()
        price :: float()
      end
    end

    test "using module syntax generates the struct" do
      assert Product2.__struct__() == %Product2{code: nil, price: nil}
    end
  end
end
