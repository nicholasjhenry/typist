defmodule Typist.DiscriminatedUnionTest do
  use ExUnit.Case
  use Typist

  describe "discriminated union" do
    alias Typist.DiscriminatedUnionTest.{Nickname, Name}

    deftype FormalName :: String.t()
    deftype Nickname :: String.t()
    deftype FirstLast :: {String.t(), String.t()}

    deftype Name :: Nickname.t() | FirstLast.t() | FormatName.t() | binary

    test "inline" do
      actual_type = Name.__type__()

      assert match?(%Typist.DiscriminatedUnionType{}, actual_type)
      assert :Name == actual_type.name

      assert [{"Nickname.t()", _}, {"FirstLast.t()", _}, {"FormatName.t()", _}, {"binary", _}] =
               actual_type.types

      assert %Name{value: %Nickname{value: "Jimmy"}}
    end

    defmodule Foo.Name do
      deftype Nickname.t() | FirstLast.t() | FormatName.t()
    end

    test "module" do
      actual_type = Foo.Name.__type__()

      assert match?(%Typist.DiscriminatedUnionType{}, actual_type)
      assert :Name == actual_type.name

      assert [{"Nickname.t()", _}, {"FirstLast.t()", _}, {"FormatName.t()", _}] =
               actual_type.types

      assert %Foo.Name{value: %Nickname{value: "Jimmy"}}
    end
  end
end
