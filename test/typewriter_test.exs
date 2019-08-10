defmodule TypeWriterTest do
  use ExUnit.Case

  use TypeWriter

  describe "defining a single case union type" do
    deftype ProductCode :: String.t()

    test "using inline syntax generates the struct" do
      alias TypeWriterTest.ProductCode

      assert ProductCode.__struct__() == %ProductCode{value: nil}
    end
  end
end
