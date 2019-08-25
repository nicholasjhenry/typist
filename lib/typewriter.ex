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

  defmodule RecordType do
    @moduledoc """
    A record type, a product type with named fields.
    """
    defstruct [:name, :fields]
  end

  defmodule Field do
    @moduledoc """
    A field in a `RecordType`.
    """
    defstruct [:name, :type]
  end

  # Record type - inline
  # deftype Product do
  #   code :: ProductCode.t()
  #   price :: float()
  # end
  # matches: deftype Product do, ... end
  defmacro deftype({:__aliases__, _, [_module]} = ast, do: block) do
    current_module = current_module(__CALLER__.module)
    type = record_type(current_module, ast, block)

    quote do
      defmodule unquote(Module.concat([type.name])) do
        def __type__ do
          unquote(Macro.escape(type))
        end
      end
    end
  end

  defp record_type(
         _current_module,
         {:__aliases__, _, [module]},
         {:__block__, _, ast_fields}
       ) do
    fields = Enum.map(ast_fields, &build_field/1)

    %TypeWriter.RecordType{
      name: module,
      fields: fields
    }
  end

  defp build_field(
         {:"::", _,
          [
            {name, _, nil},
            type_to_be_wrapped
          ]}
       ) do
    type = get_type(type_to_be_wrapped)
    %TypeWriter.Field{name: name, type: type}
  end

  # Record type - module
  # defmodule Product do
  #   deftype do
  #     code :: ProductCode.t()
  #     price :: float()
  #   end
  # end

  defmacro deftype(do: {:__block__, _, ast_fields}) do
    fields = Enum.map(ast_fields, &build_field/1)

    type = %TypeWriter.RecordType{
      name: :Product2,
      fields: fields
    }

    quote do
      def __type__ do
        unquote(Macro.escape(type))
      end
    end
  end

  defmodule SingleCaseUnionType do
    @moduledoc """
    Single case union type is used to wrap a primitive.

    https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/
    """
    defstruct [:name, :type]
  end

  # Non-record types
  defmacro deftype(ast) do
    current_module = current_module(__CALLER__.module)

    type = maybe_single_case_union_type(current_module, ast)
    type = maybe_discriminated_union_type(current_module, ast, type)
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

  defmodule DiscriminatedUnionType do
    @moduledoc """
    Single case union type is used to wrap a primitive.

    https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/
    """
    defstruct [:name, :types]
  end

  # module
  def maybe_discriminated_union_type(
        current_module,
        {:|, _, union_types},
        _type
      ) do
    types = union_types |> Enum.map(&get_type/1) |> List.flatten()

    %TypeWriter.DiscriminatedUnionType{
      name: current_module,
      types: types
    }
  end

  # inline
  def maybe_discriminated_union_type(
        _current_module,
        {:"::", _,
         [
           {:__aliases__, _, [module]},
           {:|, _, union_types}
         ]},
        :none
      ) do
    types = union_types |> Enum.map(&get_type/1) |> List.flatten()

    %TypeWriter.DiscriminatedUnionType{
      name: module,
      types: types
    }
  end

  def maybe_discriminated_union_type(_current_module, _ast, type), do: type

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
    type_info = get_type(product_types)

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
    type_info = get_type(product_types)

    %TypeWriter.SingleCaseUnionType{
      name: current_module,
      type: type_info
    }
  end

  defp maybe_product_type(_current_module, _ast, type), do: type

  # single types
  def get_type({{:., _, [{:__aliases__, _, [type_name]}, type_function]}, _, []}) do
    {type_name, type_function, []}
  end

  # union types
  def get_type({:|, [], types}) do
    Enum.map(types, &get_type/1)
  end

  # match basic types, e.g. binary, float, integer
  def get_type({type, [], _}) do
    {type, nil, []}
  end

  def get_type({:|, _, union_types}) do
    union_types |> Enum.map(&get_type/1)
  end

  # product types
  def get_type(product_types) do
    product_types |> Tuple.to_list() |> Enum.map(&get_type/1) |> List.to_tuple()
  end

  defp current_module(caller_module) do
    Module.split(caller_module) |> Enum.reverse() |> List.first() |> String.to_atom()
  end

  defp module_defined?(current_module, type_name) do
    current_module == type_name
  end
end
