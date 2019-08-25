defmodule TypeWriter.RecordTypeTest do
  use ExUnit.Case

  use TypeWriter

  describe "record type" do
    deftype Product1 do
      code :: String.t()
      price :: integer
    end

    test "inline" do
      assert match?(
               %TypeWriter.RecordType{
                 name: :Product1,
                 fields: [
                   %TypeWriter.Field{name: :code, type: {"String.t()", _}},
                   %TypeWriter.Field{name: :price, type: {"integer", _}}
                 ]
               },
               Product1.__type__()
             )

      %Product1{code: "ABC123", price: 10_00}
    end

    defmodule Product2 do
      deftype do
        code :: String.t()
        price :: integer
      end
    end

    test "module" do
      assert match?(
               %TypeWriter.RecordType{
                 name: :Product2,
                 fields: [
                   %TypeWriter.Field{name: :code, type: {"String.t()", _}},
                   %TypeWriter.Field{name: :price, type: {"integer", _}}
                 ]
               },
               Product2.__type__()
             )

      %Product2{code: "ABC123", price: 10_00}
    end
  end
end
