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
    deftype Product1 do
      code :: String.t()
      price :: String.t()
    end

    test "inline defines the meta data" do
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

    test "module defines the meta data" do
      assert Product2.__type__() == %TypeWriter.RecordType{
               name: :Product2,
               fields: [
                 %TypeWriter.Field{name: :code, type: {:String, :t, []}},
                 %TypeWriter.Field{name: :price, type: {:String, :t, []}}
               ]
             }
    end
  end

  describe "discriminated union" do
    deftype FormalName3 :: String.t()
    deftype Nickname3 :: String.t()
    deftype FirstLast3 :: {String.t(), String.t()}
    deftype Name3 :: Nickname3.t() | FirstLast3.t() | FormatName3.t()

    test "inline" do
      assert Name3.__type__() == %TypeWriter.DiscriminatedUnionType{
               name: :Name3,
               types: [{:Nickname3, :t, []}, {:FirstLast3, :t, []}, {:FormatName3, :t, []}]
             }
    end

    defmodule Name4 do
      deftype Nickname3.t() | FirstLast3.t() | FormatName3.t()
    end

    test "module" do
      assert Name4.__type__() == %TypeWriter.DiscriminatedUnionType{
               name: :Name4,
               types: [{:Nickname3, :t, []}, {:FirstLast3, :t, []}, {:FormatName3, :t, []}]
             }
    end
  end

  describe "get a type" do
    test "type wrapper for an aliased type" do
      ast = quote do: String.t()

      result = TypeWriter.get_type(ast)

      assert result == {:String, :t, []}
    end

    test "type wrapper for a basic type" do
      ast = quote do: non_neg_integer

      result = TypeWriter.get_type(ast)

      assert result == {:non_neg_integer, nil, []}
    end

    test "discrimate types with aliases returns the type" do
      ast = quote do: Nickname3.t() | FirstLast3.t() | FormatName3.t()

      result = TypeWriter.get_type(ast)

      assert List.flatten(result) == [
               {:Nickname3, :t, []},
               {:FirstLast3, :t, []},
               {:FormatName3, :t, []}
             ]
    end

    test "discrimate types with basic" do
      ast = quote do: float() | integer() | binary()

      result = TypeWriter.get_type(ast)

      assert List.flatten(result) == [
               {:float, nil, []},
               {:integer, nil, []},
               {:binary, nil, []}
             ]
    end

    test "discrimate types with mixed" do
      ast = quote do: float() | String.t() | binary()

      result = TypeWriter.get_type(ast)

      assert List.flatten(result) == [
               {:float, nil, []},
               {:String, :t, []},
               {:binary, nil, []}
             ]
    end

    test "product types with alias" do
      ast = quote do: {String.t(), String.t()}

      result = TypeWriter.get_type(ast)

      assert result == {{:String, :t, []}, {:String, :t, []}}
    end

    test "product types with basic" do
      ast = quote do: {float(), integer()}

      result = TypeWriter.get_type(ast)

      assert result == {{:float, nil, []}, {:integer, nil, []}}
    end

    test "product types with mixed" do
      ast = quote do: {String.t(), integer()}

      result = TypeWriter.get_type(ast)

      assert result == {{:String, :t, []}, {:integer, nil, []}}
    end

    test "product types with discrimited unions" do
      ast = quote do: {String.t(), integer() | float()}

      result = TypeWriter.get_type(ast)

      assert result == {{:String, :t, []}, [{:integer, nil, []}, {:float, nil, []}]}
    end
  end
end
