defmodule Typist.SingleCaseUnionTypeTest do
  use ExUnit.Case

  use Typist

  defmodule Foo do
    deftype String.t()
  end

  describe "defining a type in a module" do
    test "defines the type meta-data" do
      metadata = Foo.__type__()

      assert metadata.ast == {[:String], :t}
      assert metadata.spec == "@type(t :: %__MODULE__{value: String.t()})"
      assert metadata.constructor == "@spec(new(String.t()) :: t)"
    end

    test "defines a constructor function" do
      assert %Foo{value: "ABC123"} == Foo.new("ABC123")
    end
  end

  describe "defining a type inline as an alias for an Elixir remote type" do
    deftype Bar :: integer

    test "defines the type meta-data" do
      metadata = Bar.__type__()

      assert metadata.ast == {:basic, [], [:integer]}
      assert metadata.spec == "@type(t :: %__MODULE__{value: integer})"
      assert metadata.constructor == "@spec(new(integer) :: t)"
    end

    test "defines a constructor function" do
      assert %Bar{value: 123} == Bar.new(123)
    end
  end

  describe "defining a type inline as an alias for a product type" do
    deftype Baz :: {String.t(), integer}

    test "defines the type meta-data" do
      metadata = Baz.__type__()

      assert metadata.ast == {:product, [], [{[:String], :t}, {:basic, [], [:integer]}]}
      assert metadata.spec == "@type(t :: %__MODULE__{value: {String.t(), integer}})"
      assert metadata.constructor == "@spec(new({String.t(), integer}) :: t)"
    end

    test "defines a constructor function" do
      assert %Baz{value: {"ABC", 123}} == Baz.new({"ABC", 123})
    end
  end
end
