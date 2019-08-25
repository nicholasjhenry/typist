defmodule TypeWriter.DiscriminatedUnionTest do
  use ExUnit.Case

  use TypeWriter

  describe "discriminated union" do
    deftype FormalName3 :: String.t()
    deftype Nickname3 :: String.t()
    deftype FirstLast3 :: {String.t(), String.t()}
    deftype Name3 :: Nickname3.t() | FirstLast3.t() | FormatName3.t()

    test "inline" do
      assert Name3.__type__() == %TypeWriter.DiscriminatedUnionType{
               name: :Name3,
               types: [{:Nickname3, :t, []}, {:FirstLast3, :t, []}, {:FormatName3, :t, []}]
             }
    end

    defmodule Name4 do
      deftype Nickname3.t() | FirstLast3.t() | FormatName3.t()
    end

    test "module" do
      assert Name4.__type__() == %TypeWriter.DiscriminatedUnionType{
               name: :Name4,
               types: [{:Nickname3, :t, []}, {:FirstLast3, :t, []}, {:FormatName3, :t, []}]
             }
    end
  end
end
