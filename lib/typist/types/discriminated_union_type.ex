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
  defstruct [:name, :types, :raw]

  import Typist.{Ast, Utils}

  def build(module_path, ast, block \\ :none) do
    module_name = module_name(module_path)

    case maybe_type(module_name, ast, block) do
      :none ->
        :none

      type ->
        spec = spec(type)
        build_ast(module_name, module_path, type, spec)
    end
  end

  # Data type: discriminated union type, module
  defp maybe_type(module_name, {:|, _, union_types}, _block) do
    type(module_name, union_types)
  end

  # Data type: discriminated union type, inline
  defp maybe_type(
         _module_name,
         {:"::", _,
          [
            {:__aliases__, _, [module_name]},
            {:|, _, union_types}
          ]},
         _block
       ) do
    type(module_name, union_types)
  end

  defp maybe_type(_module_name, _ast, _block), do: :none

  defp type(module_name, union_types) do
    types = union_types |> Enum.map(&from_ast/1) |> List.flatten()

    %Typist.DiscriminatedUnionType{name: module_name, types: types, raw: union_types}
  end

  defp spec(union_types) do
    quote do
      @type t :: %__MODULE__{value: unquote({:|, [], union_types.raw})}
    end
  end
end
