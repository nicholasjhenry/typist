defmodule TypeWriter.DiscriminatedUnionTest do
  use ExUnit.Case
  use TypeWriter

  alias TypeWriter.DiscriminatedUnionTest.{Nickname3, Name3}

  describe "discriminated union" do
    deftype FormalName3 :: String.t()
    deftype Nickname3 :: String.t()
    deftype FirstLast3 :: {String.t(), String.t()}

    deftype Name3 :: Nickname3.t() | FirstLast3.t() | FormatName3.t() | binary

    test "inline" do
      assert match?(
               %TypeWriter.DiscriminatedUnionType{
                 name: :Name3,
                 types: [
                   {"Nickname3.t()", _},
                   {"FirstLast3.t()", _},
                   {"FormatName3.t()", _},
                   {"binary", _}
                 ]
               },
               Name3.__type__()
             )

      assert %Name3{value: %Nickname3{value: "Jimmy"}}
    end

    defmodule Name4 do
      deftype Nickname3.t() | FirstLast3.t() | FormatName3.t()
    end

    test "module" do
      assert match?(
               %TypeWriter.DiscriminatedUnionType{
                 name: :Name4,
                 types: [{"Nickname3.t()", _}, {"FirstLast3.t()", _}, {"FormatName3.t()", _}]
               },
               Name4.__type__()
             )

      assert %Name4{value: %Nickname3{value: "Jimmy"}}
    end
  end
end
