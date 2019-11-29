defmodule Typist.ParserTest do
  use ExUnit.Case

  alias Typist.Parser

  describe "parsing discriminiated unions" do
    test "simple" do
      ast =
        quote do
          integer
        end

      result = Parser.parse(ast)

      assert result == {:basic, [], [:integer]}
    end

    test "simple union remote type" do
      ast =
        quote do
          Qux :: integer
        end

      result = Parser.parse(ast)

      assert result == {:"::", [], [{[:Qux], :t}, {:basic, [], [:integer]}]}
    end

    test "simple union remote type alias a remote type" do
      ast =
        quote do
          Qux :: String.t()
        end

      result = Parser.parse(ast)

      assert result == {:"::", [], [{[:Qux], :t}, {[:String], :t}]}
    end

    test "simple union remote type for a function" do
      ast =
        quote do
          Qux :: (binary -> integer)
        end

      result = Parser.parse(ast)

      assert result ==
               {:"::", [],
                [{[:Qux], :t}, {:->, [], [[{:basic, [], [:binary]}]], {:basic, [], [:integer]}}]}
    end

    test "mutiple remote types" do
      ast =
        quote do
          Qux :: integer | Baz :: boolean | Zoo :: term
        end

      result = Parser.parse(ast)

      assert result ==
               {:|, [],
                [
                  {:"::", [], [{[:Qux], :t}, {:basic, [], [:integer]}]},
                  {:|, [],
                   [
                     {:"::", [], [{[:Baz], :t}, {:basic, [], [:boolean]}]},
                     {:"::", [], [{[:Zoo], :t}, {:basic, [], [:term]}]}
                   ]}
                ]}
    end

    test "multiple basic types" do
      ast =
        quote do
          integer | boolean | term
        end

      result = Parser.parse(ast)

      assert result ==
               {:|, [],
                [
                  {:basic, [], [:integer]},
                  {:|, [], [{:basic, [], [:boolean]}, {:basic, [], [:term]}]}
                ]}
    end

    test "mixed types" do
      ast =
        quote do
          integer | Foo :: boolean | Bar :: term
        end

      result = Parser.parse(ast)

      assert result ==
               {:|, [],
                [
                  {:basic, [], [:integer]},
                  {:|, [],
                   [
                     {:"::", [], [{[:Foo], :t}, {:basic, [], [:boolean]}]},
                     {:"::", [], [{[:Bar], :t}, {:basic, [], [:term]}]}
                   ]}
                ]}
    end

    test "more mixed types" do
      ast =
        quote do
          integer | boolean | any | Foo :: number | Bar :: term
        end

      result = Parser.parse(ast)

      assert result ==
               {:|, [],
                [
                  {:basic, [], [:integer]},
                  {:|, [],
                   [
                     {:basic, [], [:boolean]},
                     {:|, [],
                      [
                        {:basic, [], [:any]},
                        {:|, [],
                         [
                           {:"::", [], [{[:Foo], :t}, {:basic, [], [:number]}]},
                           {:"::", [], [{[:Bar], :t}, {:basic, [], [:term]}]}
                         ]}
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

      assert result == {:product, [], [{:basic, [], [:integer]}, {:basic, [], [:boolean]}]}
    end

    test "simple with remote types" do
      ast =
        quote do
          {Qux.t(), Bar.t()}
        end

      result = Parser.parse(ast)

      assert result == {:product, [], [{[:Qux], :t}, {[:Bar], :t}]}
    end

    test "simple with remote types aliasing" do
      ast =
        quote do
          {Qux :: integer, Bar.t()}
        end

      result = Parser.parse(ast)

      assert result ==
               {:product, [],
                [{:"::", [], [{[:Qux], :t}, {:basic, [], [:integer]}]}, {[:Bar], :t}]}
    end

    test "simple alias with atoms" do
      ast =
        quote do
          {:some, any} | :none
        end

      result = Parser.parse(ast)

      assert result == {:|, [], [{:product, [], [:some, {:basic, [], [:any]}]}, :none]}
    end
  end

  describe "record types" do
    test "fields with basic types" do
      ast =
        quote do
          code :: binary
          price :: integer
        end

      result = Parser.parse(ast)

      assert result ==
               {:record, [],
                [{:code, {:basic, [], [:binary]}}, {:price, {:basic, [], [:integer]}}]}
    end

    test "fields with remote types" do
      ast =
        quote do
          code :: Foo.t()
          price :: integer
        end

      result = Parser.parse(ast)

      assert result == {:record, [], [{:code, {[:Foo], :t}}, {:price, {:basic, [], [:integer]}}]}
    end

    test "fields with product types" do
      ast =
        quote do
          code :: {integer, boolean}
          price :: integer
        end

      result = Parser.parse(ast)

      assert result ==
               {:record, [],
                [
                  {:code, {:product, [], [{:basic, [], [:integer]}, {:basic, [], [:boolean]}]}},
                  {:price, {:basic, [], [:integer]}}
                ]}
    end

    test "fields with union types" do
      ast =
        quote do
          code :: integer | boolean
          price :: integer
        end

      result = Parser.parse(ast)

      assert result ==
               {:record, [],
                [
                  {:code, {:|, [], [{:basic, [], [:integer]}, {:basic, [], [:boolean]}]}},
                  {:price, {:basic, [], [:integer]}}
                ]}
    end

    test "fields with union Remote types" do
      ast =
        quote do
          code :: Foo.t() | boolean
          price :: integer
        end

      result = Parser.parse(ast)

      assert result ==
               {:record, [],
                [
                  {:code, {:|, [], [{[:Foo], :t}, {:basic, [], [:boolean]}]}},
                  {:price, {:basic, [], [:integer]}}
                ]}
    end
  end
end
