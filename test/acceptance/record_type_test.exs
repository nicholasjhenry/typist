defmodule TypeWriter.RecordTypeTest do
  use ExUnit.Case

  use TypeWriter

  describe "record type" do
    deftype Product1 do
      code :: String.t()
      price :: String.t()
    end

    test "inline" do
      assert Product1.__type__() == %TypeWriter.RecordType{
               name: :Product1,
               fields: [
                 %TypeWriter.Field{name: :code, type: {:String, :t, []}},
                 %TypeWriter.Field{name: :price, type: {:String, :t, []}}
               ]
             }
    end

    defmodule Product2 do
      deftype do
        code :: String.t()
        price :: String.t()
      end
    end

    test "module" do
      assert Product2.__type__() == %TypeWriter.RecordType{
               name: :Product2,
               fields: [
                 %TypeWriter.Field{name: :code, type: {:String, :t, []}},
                 %TypeWriter.Field{name: :price, type: {:String, :t, []}}
               ]
             }
    end
  end
end
