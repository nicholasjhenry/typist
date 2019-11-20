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
      assert match?(
               %Typist.DiscriminatedUnionType{
                 name: :Name,
                 types: [
                   {"Nickname.t()", _},
                   {"FirstLast.t()", _},
                   {"FormatName.t()", _},
                   {"binary", _}
                 ]
               },
               Name.__type__()
             )

      assert %Name{value: %Nickname{value: "Jimmy"}}
    end

    defmodule Foo.Name do
      deftype Nickname.t() | FirstLast.t() | FormatName.t()
    end

    test "module" do
      assert match?(
               %Typist.DiscriminatedUnionType{
                 name: :Name,
                 types: [{"Nickname.t()", _}, {"FirstLast.t()", _}, {"FormatName.t()", _}]
               },
               Foo.Name.__type__()
             )

      assert %Foo.Name{value: %Nickname{value: "Jimmy"}}
    end
  end
end
