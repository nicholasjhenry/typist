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
end
