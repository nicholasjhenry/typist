defmodule TypeWriterTest do
  use ExUnit.Case

  use TypeWriter

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
