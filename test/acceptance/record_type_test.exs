defmodule Typist.RecordTypeTest do
  use ExUnit.Case
  use Typist

  describe "defining the type inline" do
    deftype Product do
      code :: String.t()
      price :: integer
    end

    test "defines the type meta-data" do
      actual_type = Product.__type__()

      assert match?(%Typist.RecordType{}, actual_type)
      assert :Product == actual_type.name

      assert [
               %Typist.RecordType.Field{name: :code, type: {"String.t()", _}},
               %Typist.RecordType.Field{name: :price, type: {"integer", _}}
             ] = actual_type.fields

      assert actual_type.spec == "@type(t :: %__MODULE__{code: String.t(), price: integer})"
    end

    test "defines a constructor function" do
      assert %Product{code: "ABC123", price: 10_00} == Product.new(code: "ABC123", price: 10_00)
    end
  end

  describe "defining the type in a module" do
    defmodule Foo.Product do
      deftype do
        code :: String.t()
        price :: integer
      end
    end

    test "defines the type meta-data" do
      actual_type = Foo.Product.__type__()

      assert match?(%Typist.RecordType{}, actual_type)
      assert :Product == actual_type.name

      assert [
               %Typist.RecordType.Field{name: :code, type: {"String.t()", _}},
               %Typist.RecordType.Field{name: :price, type: {"integer", _}}
             ] = actual_type.fields
    end

    test "defines a constructor function" do
      assert %Foo.Product{code: "ABC123", price: 10_00} ==
               Foo.Product.new(code: "ABC123", price: 10_00)
    end
  end
end
