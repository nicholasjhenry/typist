defmodule TypeWriterTest do
  use ExUnit.Case

  use TypeWriter

  describe "defining a single case union type" do
    deftype ProductCode1 :: String.t()

    test "inline defines the meta data" do
      assert ProductCode1.__type__() == %TypeWriter.SingleCaseUnionType{
               name: :ProductCode1,
               type: {:String, :t, []}
             }
    end

    defmodule ProductCode2 do
      use TypeWriter

      deftype String.t()
    end

    test "module defines the meta data" do
      assert ProductCode2.__type__() == %TypeWriter.SingleCaseUnionType{
               name: :ProductCode2,
               type: {:String, :t, []}
             }
    end
  end

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

  describe "record type" do
    deftype Product do
      code :: String.t()
      price :: String.t()
    end

    test "inline defines the meta data" do
      assert Product.__type__() == %TypeWriter.RecordType{
               name: :Product,
               fields: [
                 %TypeWriter.Field{name: :code, type: {:String, :t, []}},
                 %TypeWriter.Field{name: :price, type: {:String, :t, []}}
               ]
             }
    end
  end
end
