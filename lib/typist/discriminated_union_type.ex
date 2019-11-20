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

  import Typist.{Ast, Utils}

  def build(module, ast, block \\ :none) do
    current_module = current_module(module)

    case maybe_type(current_module, ast, block) do
      :none ->
        :none

      type ->
        spec = spec(type)
        build_ast(current_module, module, type, spec)
    end
  end

  def spec(_union_type) do
    quote do
    end
  end

  # Data type: discriminated union type, module
  def maybe_type(
        current_module,
        {:|, _, union_types},
        _block
      ) do
    types = union_types |> Enum.map(&from_ast/1) |> List.flatten()

    %Typist.DiscriminatedUnionType{
      name: current_module,
      types: types
    }
  end

  # Data type: discriminated union type, inline
  def maybe_type(
        _current_module,
        {:"::", _,
         [
           {:__aliases__, _, [module]},
           {:|, _, union_types}
         ]},
        _block
      ) do
    types = union_types |> Enum.map(&from_ast/1) |> List.flatten()

    %Typist.DiscriminatedUnionType{
      name: module,
      types: types
    }
  end

  def maybe_type(_current_module, _ast, _block), do: :none
end
