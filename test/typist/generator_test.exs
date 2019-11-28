defmodule Typist.GeneratorTest do
  use ExUnit.Case

  use Typist

  describe "generating a union type" do
    deftype ContactInfo,
      do: EmailOnly :: EmailContactInfo.t() | PostOnly :: PostContactInfo.t() | String.t()

    test "creates the embedded modules" do
      assert ContactInfo.__type__()
      assert EmailOnly.__type__()
    end
  end

  describe "generating a record type" do
    deftype Qux.ContactInfo do
      email :: Email.t()
      price :: integer
    end

    test "creates the embedded modules" do
      assert Qux.ContactInfo.__type__()
    end
  end

  describe "generating a product type" do
    defmodule Foo do
      deftype {Baz :: integer, String.t()}
    end

    test "creates the embedded modules" do
      assert Foo.Baz.__type__()
    end
  end
end
