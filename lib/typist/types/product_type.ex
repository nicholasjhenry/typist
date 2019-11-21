defmodule Typist.ProductType do
  @moduledoc """
  Creating new types by “multiplying” existing types together.

  From: https://fsharpforfunandprofit.com/posts/designing-with-types-intro/

  > Guideline: Use records or tuples (product type) to group together data that are required to
  > be consistent (that is “atomic”) but don’t needlessly group together data that is not related.

  Example:

      deftype Product :: {String.t, integer()}
  """

  @enforce_keys [:name, :ast, :spec, :module_path, :defined]
  defstruct [:name, :ast, :spec, :module_path, :defined]

  import Typist.{Ast, Module}

  def build(module_path, ast, block \\ :none) do
    module_name = module_name(module_path)

    case maybe_type(module_name, module_path, ast, block) do
      :none ->
        :none

      type ->
        build_ast(type)
    end
  end

  # Data type: product type, inline
  #
  # deftype FirstLast :: {String.t(), String.t()}
  defp maybe_type(
         _module_name,
         module_path,
         {
           :"::",
           _,
           [{:__aliases__, _, [type_name]}, ast]
         },
         _block
       ) do
    type(type_name, module_path, ast, :inline)
  end

  # Data type: product type, module
  #
  # defmodule FirstLast2 do
  #   use Typist
  #
  #   deftype {String.t(), String.t()}
  # end
  defp maybe_type(type_name, module_path, ast, _block) when is_tuple(ast) do
    type(type_name, module_path, ast, :module)
  end

  defp maybe_type(_type_name, _module_path, _ast, _block), do: :none

  defp type(type_name, module_path, ast, defined) do
    %Typist.ProductType{
      name: type_name,
      module_path: module_path,
      ast: ast,
      spec: spec(ast),
      defined: defined
    }
  end

  defp spec(value) do
    quote do
      @type t :: %__MODULE__{value: unquote(value)}
    end
  end
end
