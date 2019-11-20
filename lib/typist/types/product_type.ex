defmodule Typist.ProductType do
  @moduledoc """
  Creating new types by “multiplying” existing types together.

  From: https://fsharpforfunandprofit.com/posts/designing-with-types-intro/

  > Guideline: Use records or tuples (product type) to group together data that are required to
  > be consistent (that is “atomic”) but don’t needlessly group together data that is not related.

  Example:

      deftype Product :: {String.t, integer()}
  """

  @enforce_keys [:name, :type]
  defstruct [:name, :type]

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

  # Data type: product type, inline
  #
  # deftype FirstLast :: {String.t(), String.t()}
  defp maybe_type(
         _module_name,
         {
           :"::",
           _,
           [{:__aliases__, _, [module_name]}, product_types]
         },
         _block
       ) do
    type(module_name, product_types)
  end

  # Data type: product type, module
  #
  # defmodule FirstLast2 do
  #   use Typist
  #
  #   deftype {String.t(), String.t()}
  # end
  defp maybe_type(module_name, product_types, _block) do
    type(module_name, product_types)
  end

  # def maybe_type(_module_name, _ast), do: :none

  defp type(module_name, product_types) do
    %Typist.ProductType{
      name: module_name,
      type: from_ast(product_types)
    }
  end

  defp spec(product_type) do
    {_, ast} = product_type.type

    quote do
      @type t :: %__MODULE__{value: unquote(ast)}
    end
  end
end
