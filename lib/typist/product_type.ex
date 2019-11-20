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

  # Data type: product type, inline
  #
  # deftype FirstLast :: {String.t(), String.t()}
  defp maybe_type(
         _current_module,
         {
           :"::",
           _,
           [{:__aliases__, _, [module]}, product_types]
         },
         _block
       ) do
    type_info = from_ast(product_types)

    %Typist.ProductType{
      name: module,
      type: type_info
    }
  end

  # Data type: product type, module
  #
  # defmodule FirstLast2 do
  #   use Typist
  #
  #   deftype {String.t(), String.t()}
  # end
  defp maybe_type(current_module, product_types, _block) do
    type_info = from_ast(product_types)

    %Typist.ProductType{
      name: current_module,
      type: type_info
    }
  end

  # def maybe_type(_current_module, _ast), do: :none

  defp spec(product_type) do
    {_, ast} = product_type.type

    quote do
      @type t :: %__MODULE__{value: unquote(ast)}
    end
  end
end
