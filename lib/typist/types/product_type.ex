defmodule Typist.ProductType do
  @moduledoc """
  Creating new types by “multiplying” existing types together.

  From: https://fsharpforfunandprofit.com/posts/designing-with-types-intro/

  > Guideline: Use records or tuples (product type) to group together data that are required to
  > be consistent (that is “atomic”) but don’t needlessly group together data that is not related.

  Example:

      deftype Product :: {String.t, integer()}
  """

  @enforce_keys [:name, :type, :value, :spec, :module_path]
  defstruct [:name, :type, :value, :spec, :module_path]

  import Typist.{Ast, Utils}

  def build(module_path, ast, block \\ :none) do
    module_name = module_name(module_path)

    case maybe_type(module_name, module_path, ast, block) do
      :none ->
        :none

      type ->
        build_ast(module_name, type)
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
           [{:__aliases__, _, [module_name]}, product_types]
         },
         _block
       ) do
    type(module_name, module_path, product_types)
  end

  # Data type: product type, module
  #
  # defmodule FirstLast2 do
  #   use Typist
  #
  #   deftype {String.t(), String.t()}
  # end
  defp maybe_type(module_name, module_path, product_types, _block) do
    type(module_name, module_path, product_types)
  end

  # def maybe_type(_module_name, _ast), do: :none

  defp type(module_name, module_path, product_types) do
    type = from_ast(product_types)
    {_, value} = type

    %Typist.ProductType{
      name: module_name,
      module_path: module_path,
      type: type,
      value: value,
      spec: spec(value)
    }
  end

  defp spec(value) do
    quote do
      @type t :: %__MODULE__{value: unquote(value)}
    end
  end
end
