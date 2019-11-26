defmodule Typist.ParserTest do
  use ExUnit.Case

  alias Typist.Parser

  describe "parsing discriminiated unions" do
    test "simple union remote type" do
      ast =
        quote do
          Qux.t() :: integer
        end

      result = Parser.parse(ast)

      assert result == {:"::", [], [{:Qux, :t}, :integer]}
    end

    test "mutiple remote types" do
      ast =
        quote do
          Qux.t() :: integer | Baz.t() :: boolean | Zoo.t() :: term
        end

      result = Parser.parse(ast)

      assert result ==
               {:|,
                [
                  {:"::", [], [{:Qux, :t}, :integer]},
                  {:|, [], [{:"::", [{:Baz, :t}, :boolean]}, {:"::", [], [{:Zoo, :t}, :term]}]}
                ]}
    end

    test "multiple basic types" do
      ast =
        quote do
          integer | boolean | term
        end

      result = Parser.parse(ast)

      assert result == {:|, [], [:integer, {:|, [], [:boolean, :term]}]}
    end

    test "mixed types" do
      ast =
        quote do
          integer | Foo.t() :: boolean | Bar.t() :: term
        end

      result = Parser.parse(ast)

      assert result ==
               {:|, [],
                [
                  :integer,
                  {:|, [], [{:"::", [{:Foo, :t}, :boolean]}, {:"::", [], [{:Bar, :t}, :term]}]}
                ]}
    end

    test "more mixed types" do
      ast =
        quote do
          integer | boolean | any | Foo.t() :: number | Bar.t() :: term
        end

      result = Parser.parse(ast)

      assert result ==
               {:|, [],
                [
                  :integer,
                  {:|, [],
                   [
                     :boolean,
                     {:|, [],
                      [
                        :any,
                        {:|, [],
                         [{:"::", [], [{:Foo, :t}, :number]}, {:"::", [], [{:Bar, :t}, :term]}]}
                      ]}
                   ]}
                ]}
    end
  end

  describe "product types" do
    test "simple with basic types" do
      ast =
        quote do
          {integer, boolean}
        end

      result = Parser.parse(ast)

      assert result == {:integer, :boolean}
    end

    test "simple with remote types" do
      ast =
        quote do
          {Qux.t(), Bar.t()}
        end

      result = Parser.parse(ast)

      assert result == {{:Qux, :t}, {:Bar, :t}}
    end

    test "simple with remote types aliasing" do
      ast =
        quote do
          {Qux.t() :: integer, Bar.t()}
        end

      result = Parser.parse(ast)

      assert result == {{:"::", [], [{:Qux, :t}, :integer]}, {:Bar, :t}}
    end
  end
end
