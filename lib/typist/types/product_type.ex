defmodule Typist.ProductType do
  @moduledoc """
  Creating new types by “multiplying” existing types together.

  From: https://fsharpforfunandprofit.com/posts/designing-with-types-intro/

  > Guideline: Use records or tuples (product type) to group together data that are required to
  > be consistent (that is “atomic”) but don’t needlessly group together data that is not related.

  Example:

      deftype Product :: {String.t, integer()}
  """

  @enforce_keys [:name, :type, :value, :spec, :module_path, :defined]
  defstruct [:name, :type, :value, :spec, :module_path, :defined]

  import Typist.{Ast, Utils}

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
           [{:__aliases__, _, [type_name]}, product_types]
         },
         _block
       ) do
    type(type_name, module_path, product_types, :inline)
  end

  # Data type: product type, module
  #
  # defmodule FirstLast2 do
  #   use Typist
  #
  #   deftype {String.t(), String.t()}
  # end
  defp maybe_type(type_name, module_path, product_types, _block) do
    type(type_name, module_path, product_types, :module)
  end

  # def maybe_type(_module_name, _ast), do: :none

  defp type(type_name, module_path, product_types, defined) do
    type = from_ast(product_types)
    {_, value} = type

    %Typist.ProductType{
      name: type_name,
      module_path: module_path,
      type: type,
      value: value,
      spec: spec(value),
      defined: defined
    }
  end

  defp spec(value) do
    quote do
      @type t :: %__MODULE__{value: unquote(value)}
    end
  end
end
