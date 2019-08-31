defmodule Typist.RecordTypeTest do
  use ExUnit.Case
  use Typist

  alias Typist.RecordTypeTest.Product1

  describe "record type" do
    deftype Product1 do
      code :: String.t()
      price :: integer
    end

    test "inline" do
      assert match?(
               %Typist.RecordType{
                 name: :Product1,
                 fields: [
                   %Typist.Field{name: :code, type: {"String.t()", _}},
                   %Typist.Field{name: :price, type: {"integer", _}}
                 ]
               },
               Product1.__type__()
             )

      Product1.new(code: "ABC123", price: 10_00)
    end

    defmodule Product2 do
      deftype do
        code :: String.t()
        price :: integer
      end
    end

    test "module" do
      assert match?(
               %Typist.RecordType{
                 name: :Product2,
                 fields: [
                   %Typist.Field{name: :code, type: {"String.t()", _}},
                   %Typist.Field{name: :price, type: {"integer", _}}
                 ]
               },
               Product2.__type__()
             )

      Product2.new(%{code: "ABC123", price: 10_00})
    end
  end
end
