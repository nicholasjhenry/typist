defmodule Typist.SingleCaseUnionTypeTest do
  use ExUnit.Case

  use Typist

  defmodule Foo do
    deftype String.t()
  end

  describe "defining a type in a module" do
    test "defines the type meta-data" do
      metadata = Foo.__type__()

      assert %Foo{value: "ABC"}
      assert metadata.spec == "@type(t :: %__MODULE__{value: String.t()})"
    end
  end

  describe "defining a type inline as an alias for an Elixir remote type" do
    deftype Bar :: integer

    test "defines the type meta-data" do
      metadata = Bar.__type__()

      assert %Bar{value: 123}
      assert metadata.spec == "@type(t :: %__MODULE__{value: integer})"
    end
  end

  describe "defining a type inline as an alias for a product type" do
    deftype Baz :: {String.t(), integer}

    test "defines the type meta-data" do
      metadata = Baz.__type__()

      assert %Baz{value: {"ABC", 123}}
      assert metadata.spec == "@type(t :: %__MODULE__{value: {String.t(), integer}})"
    end
  end
end
