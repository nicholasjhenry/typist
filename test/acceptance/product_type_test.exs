defmodule Typist.ProductTypeTest do
  use ExUnit.Case
  use Typist

  describe "defining the type inline" do
    deftype FirstLast :: {String.t(), integer}

    test "defines the type meta-data" do
      metadata = FirstLast.__type__()

      assert metadata.ast == {:product, [], [{[:String], :t}, :integer]}
      assert metadata.spec == "@type(t :: %__MODULE__{value: {String.t(), integer}})"
    end
  end

  describe "defining the type in a module" do
    defmodule Foo.FirstLast do
      use Typist

      deftype {String.t(), integer}
    end

    test "defines the type meta-data" do
      metadata = Foo.FirstLast.__type__()

      assert metadata.ast == {:product, [], [{[:String], :t}, :integer]}
      assert metadata.spec == "@type(t :: %__MODULE__{value: {String.t(), integer}})"
    end
  end
end
