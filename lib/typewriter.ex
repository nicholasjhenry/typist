defmodule TypeWriter do
  @moduledoc """
  A DSL for defining types inspired by F#.
  """

  # Types:
  # -

  defmacro __using__(_opts) do
    quote do
      import TypeWriter
    end
  end

  defmacro deftype(ast) do
    current_module = current_module(__CALLER__.module)
    type = maybe_single_case_union_type(current_module, ast)

    type = maybe_product_type(current_module, ast, type)

    if module_defined?(current_module, type.name) do
      quote do
        def __type__ do
          unquote(Macro.escape(type))
        end
      end
    else
      quote do
        defmodule unquote(Module.concat([type.name])) do
          def __type__ do
            unquote(Macro.escape(type))
          end
        end
      end
    end
  end

  # https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/
  defmodule SingleCaseUnionType do
    @moduledoc """
    Single case union type is used to wrap a primitive.
    """
    defstruct [:name, :type]
  end

  # Example: "Single case union type - inline"
  # deftype ProductCode1 :: String.t()
  def maybe_single_case_union_type(
        _current_module,
        {
          :"::",
          _,
          [{:__aliases__, _, [module]}, {{:., _, [_, _]}, _, []} = type_to_be_wrapped]
        }
      ) do
    %TypeWriter.SingleCaseUnionType{
      name: module,
      type: get_type(type_to_be_wrapped)
    }
  end

  # Example: "Single case union type - module"
  # defmodule ProductCode2 do
  #   use TypeWriter
  #
  #   deftype String.t()
  # end
  def maybe_single_case_union_type(
        current_module,
        {{:., _, [_, _]}, _, []} = type_to_be_wrapped
      ) do
    %TypeWriter.SingleCaseUnionType{
      name: current_module,
      type: get_type(type_to_be_wrapped)
    }
  end

  def maybe_single_case_union_type(_current_module, _ast), do: :none

  defp get_type({{:., _, [{:__aliases__, _, [type_name]}, type_function]}, _, []}) do
    {type_name, type_function, []}
  end

  # Product type - inline
  # deftype FirstLast :: {String.t(), String.t()}
  defp maybe_product_type(
         _current_module,
         {
           :"::",
           _,
           [{:__aliases__, _, [module]}, product_types]
         },
         :none
       ) do
    type_info = product_types |> Tuple.to_list() |> Enum.map(&get_type/1) |> List.to_tuple()

    %TypeWriter.SingleCaseUnionType{
      name: module,
      type: type_info
    }
  end

  # Product type - module
  # defmodule FirstLast2 do
  #   use TypeWriter
  #
  #   deftype {String.t(), String.t()}
  # end
  defp maybe_product_type(current_module, product_types, :none) do
    type_info = product_types |> Tuple.to_list() |> Enum.map(&get_type/1) |> List.to_tuple()

    %TypeWriter.SingleCaseUnionType{
      name: current_module,
      type: type_info
    }
  end

  defp maybe_product_type(_current_module, _ast, type), do: type

  defp current_module(caller_module) do
    Module.split(caller_module) |> Enum.reverse() |> List.first() |> String.to_atom()
  end

  defp module_defined?(current_module, type_name) do
    current_module == type_name
  end
end
