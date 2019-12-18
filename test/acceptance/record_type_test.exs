defmodule Typist.RecordTypeTest do
  use ExUnit.Case
  use Typist

  describe "defining the type inline" do
    deftype Product do
      code :: String.t()
      price :: integer()
    end

    test "defines the type meta-data" do
      metadata = Product.__type__()

      assert %Product{code: "ABC", price: 10_00}
      assert metadata.spec == "@type(t :: %__MODULE__{code: String.t(), price: integer()})"
    end
  end
end
