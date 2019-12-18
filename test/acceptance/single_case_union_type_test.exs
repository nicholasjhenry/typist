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

      assert %Bar{value: 123}
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

      assert %Baz{value: {"ABC", 123}}
      assert metadata.spec == "@type(t :: %__MODULE__{value: {String.t(), integer}})"
      assert metadata.constructor == "@spec(new({String.t(), integer}) :: t)"
    end

    test "defines a constructor function" do
      assert %Baz{value: {"ABC", 123}} == Baz.new({"ABC", 123})
    end
  end

  describe "applying" do
    test "applies the function to the unwrapped value" do
      product_code = Foo.new("ABC123")
      func = fn value -> "value is #{value}" end
      assert "value is ABC123" == Foo.apply(product_code, func)
    end
  end

  describe "unwrapping" do
    test "returns the wrapped value" do
      product_code = Foo.new("ABC123")
      assert "ABC123" == Foo.value(product_code)
    end
  end

  import ExUnit.CaptureIO

  describe "inspecting" do
    test "returns a string representation for a value does implement String.Chars" do
      value = Foo.new("hello world")

      inspection = fn -> IO.inspect(value) end
      assert capture_io(inspection) == "#Typist.SingleCaseUnionTypeTest.Foo<hello world>\n"
    end

    test "returns a string representation for a value that does not implement String.Chars" do
      value = Foo.new({:foo, "bar"})

      inspection = fn -> IO.inspect(value) end
      assert capture_io(inspection) == "#Typist.SingleCaseUnionTypeTest.Foo<{:foo, \"bar\"}>\n"
    end
  end
end
