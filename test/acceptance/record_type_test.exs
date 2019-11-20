defmodule Typist.RecordTypeTest do
  use ExUnit.Case
  use Typist

  describe "record type" do
    alias Typist.RecordTypeTest.Product

    deftype Product do
      code :: String.t()
      price :: integer
    end

    test "inline" do
      assert match?(
               %Typist.RecordType{
                 name: :Product,
                 fields: [
                   %Typist.RecordType.Field{name: :code, type: {"String.t()", _}},
                   %Typist.RecordType.Field{name: :price, type: {"integer", _}}
                 ]
               },
               Product.__type__()
             )

      Product.new(code: "ABC123", price: 10_00)
    end

    defmodule Foo.Product do
      deftype do
        code :: String.t()
        price :: integer
      end
    end

    test "module" do
      assert match?(
               %Typist.RecordType{
                 name: :Product,
                 fields: [
                   %Typist.RecordType.Field{name: :code, type: {"String.t()", _}},
                   %Typist.RecordType.Field{name: :price, type: {"integer", _}}
                 ]
               },
               Foo.Product.__type__()
             )

      assert Foo.Product.new(%{code: "ABC123", price: 10_00})
    end
  end
end
