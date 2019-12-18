defmodule Typist.DiscriminatedUnionTypeTest do
  use ExUnit.Case
  doctest Typist

  use Typist

  describe "defining the type inline" do
    deftype FormalName :: String.t()
    deftype Nickname :: String.t()
    deftype FirstLast :: {String.t(), String.t()}

    deftype Name :: Nickname.t() | FirstLast.t() | FormalName.t() | binary

    test "defines the type meta-data" do
      metadata = Name.__type__()

      assert metadata.spec ==
               "@type(t :: Nickname.t() | FirstLast.t() | FormalName.t() | binary)"
    end
  end
end
