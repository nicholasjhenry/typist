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

      assert metadata.ast ==
               {:|, [],
                [
                  {:Nickname, :t},
                  {:|, [], [{:FirstLast, :t}, {:|, [], [{:FormalName, :t}, :binary]}]}
                ]}
    end
  end

  describe "defining the type in a module" do
    defmodule Baz do
      deftype Nickname :: String.t()

      defmodule Name do
        deftype Nickname.t() | FirstLast.t() | FormalName.t()
      end
    end

    test "defines the type meta-data" do
      metadata = Baz.Name.__type__()

      assert metadata.ast ==
               {:|, [], [{:Nickname, :t}, {:|, [], [FirstLast: :t, FormalName: :t]}]}
    end
  end

  describe "defining multiple inline remote aliases" do
    deftype ContactInfo do
      EmailOnly ::
        EmailContactInfo.t() | PostOnly ::
        PostContactInfo.t() | EmailAndPost :: {EmailContactInfo.t(), PostalContactInfo.t()}
    end

    test "defines the remote alias" do
      metadata = ContactInfo.__type__()

      assert metadata.ast ==
               {:|, [],
                [
                  {:"::", [], [EmailOnly: :t, EmailContactInfo: :t]},
                  {:|, [],
                   [
                     {:"::", [], [PostOnly: :t, PostContactInfo: :t]},
                     {:"::", [],
                      [
                        {:EmailAndPost, :t},
                        {:product, [], [{:EmailContactInfo, :t}, {:PostalContactInfo, :t}]}
                      ]}
                   ]}
                ]}

      EmailOnly.__type__()
    end
  end
end
