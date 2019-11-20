defmodule Typist.DiscriminatedUnionType do
  @moduledoc """
  Create new types by “summing” existing types.

  https://fsharpforfunandprofit.com/posts/discriminated-unions/

  Example:

      deftype Nickname :: String.t
      deftype FirstLast :: {String.t, String.t}
      deftype Name :: Nickname.t | FirstLast.t
  """

  @enforce_keys [:name, :types]
  defstruct [:name, :types]

  import Typist.Utils

  # Data type: discriminated union type, module
  def maybe_build(
        current_module,
        {:|, _, union_types},
        _type
      ) do
    types = union_types |> Enum.map(&from_ast/1) |> List.flatten()

    %Typist.DiscriminatedUnionType{
      name: current_module,
      types: types
    }
  end

  # Data type: discriminated union type, inline
  def maybe_build(
        _current_module,
        {:"::", _,
         [
           {:__aliases__, _, [module]},
           {:|, _, union_types}
         ]},
        :none
      ) do
    types = union_types |> Enum.map(&from_ast/1) |> List.flatten()

    %Typist.DiscriminatedUnionType{
      name: module,
      types: types
    }
  end

  def maybe_build(_current_module, _ast, type), do: type
end
