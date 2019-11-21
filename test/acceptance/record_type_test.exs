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
      actual_type = Product.__type__()

      assert match?(%Typist.RecordType{}, actual_type)
      assert :Product == actual_type.name

      assert [
               %Typist.RecordType.Field{name: :code, type: {"String.t()", _}},
               %Typist.RecordType.Field{name: :price, type: {"integer", _}}
             ] = actual_type.fields

      Product.new(code: "ABC123", price: 10_00)
    end

    defmodule Foo.Product do
      deftype do
        code :: String.t()
        price :: integer
      end
    end

    test "module" do
      actual_type = Foo.Product.__type__()

      assert match?(%Typist.RecordType{}, actual_type)
      assert :Product == actual_type.name

      assert [
               %Typist.RecordType.Field{name: :code, type: {"String.t()", _}},
               %Typist.RecordType.Field{name: :price, type: {"integer", _}}
             ] = actual_type.fields

      assert Foo.Product.new(%{code: "ABC123", price: 10_00})
    end
  end
end
