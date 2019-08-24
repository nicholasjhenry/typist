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
    defstruct [:name, :type]
  end

  # Example: "Single case union type - inline"
  # deftype ProductCode1 :: String.t()
  def maybe_single_case_union_type(
        _current_module,
        {:"::", _,
         [
           {:__aliases__, _, [module]},
           {{:., _, [{:__aliases__, _, [type_name]}, type_function]}, _, []}
         ]}
      ) do
    %TypeWriter.SingleCaseUnionType{
      name: module,
      type: {type_name, type_function, []}
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
        {{:., _, [{:__aliases__, _, [type_name]}, type_function]}, _, []}
      ) do
    %TypeWriter.SingleCaseUnionType{
      name: current_module,
      type: {type_name, type_function, []}
    }
  end

  defp current_module(caller_module) do
    Module.split(caller_module) |> Enum.reverse() |> List.first() |> String.to_atom()
  end

  defp module_defined?(current_module, type_name) do
    current_module == type_name
  end
end
