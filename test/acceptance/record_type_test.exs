defmodule TypeWriter.RecordTypeTest do
  use ExUnit.Case

  use TypeWriter

  describe "record type" do
    deftype Product1 do
      code :: String.t()
      price :: String.t()
    end

    test "inline" do
      assert match?(
               %TypeWriter.RecordType{
                 name: :Product1,
                 fields: [
                   %TypeWriter.Field{name: :code, type: {"String.t()", _}},
                   %TypeWriter.Field{name: :price, type: {"String.t()", _}}
                 ]
               },
               Product1.__type__()
             )
    end

    defmodule Product2 do
      deftype do
        code :: String.t()
        price :: String.t()
      end
    end

    test "module" do
      assert match?(
               %TypeWriter.RecordType{
                 name: :Product2,
                 fields: [
                   %TypeWriter.Field{name: :code, type: {"String.t()", _}},
                   %TypeWriter.Field{name: :price, type: {"String.t()", _}}
                 ]
               },
               Product2.__type__()
             )
    end
  end
end
