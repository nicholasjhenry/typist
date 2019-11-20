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

  alias Typist.Ast
  import Typist.Utils

  def build(module, ast, _block \\ :none) do
    current_module = current_module(module)

    case maybe_type(current_module, ast) do
      :none ->
        :none

      type ->
        spec = spec(type)
        Ast.build(current_module, module, type, spec)
    end
  end

  def spec(_union_type) do
    quote do
    end
  end

  # Data type: discriminated union type, module
  def maybe_type(
        current_module,
        {:|, _, union_types}
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
         ]}
      ) do
    types = union_types |> Enum.map(&from_ast/1) |> List.flatten()

    %Typist.DiscriminatedUnionType{
      name: module,
      types: types
    }
  end

  def maybe_type(_current_module, _ast), do: :none
end
