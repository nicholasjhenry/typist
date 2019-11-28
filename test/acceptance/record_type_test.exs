defmodule Typist.RecordTypeTest do
  use ExUnit.Case
  use Typist

  describe "defining the type inline" do
    deftype Product do
      code :: String.t()
      price :: integer
    end

    test "defines the type meta-data" do
      metadata = Product.__type__()

      assert metadata.ast == {:record, [], [{:code, {[:String], :t}}, {:price, :integer}]}
      assert metadata.spec == "@type(t :: %__MODULE__{code: String.t(), price: integer})"
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
      metadata = Foo.Product.__type__()

      assert metadata.ast == {:record, [], [{:code, {[:String], :t}}, {:price, :integer}]}
      assert metadata.spec == "@type(t :: %__MODULE__{code: String.t(), price: integer})"
    end
  end
end
