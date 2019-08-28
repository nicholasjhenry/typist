defmodule TypeWriter do
  @moduledoc """
  A DSL to define types inspired by libraries such as TypedStruct, Algae and the F# language.

  ## Definitions

  * Discriminated union (disjoint union, sum type):
  * Product type (record):

  ## References:

  * [Designing with Types Series](https://fsharpforfunandprofit.com/posts/designing-with-types-intro/)

  ## Single Case Union Type

  See: [Designing with types: Single case union types](https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/)

      iex> use TypeWriter
      ...> deftype ProductCodeA :: String.t
      ...> TypewriterTest.ProductCodeA.__info__(:module)
      TypewriterTest.ProductCodeA

      iex> defmodule ProductCodeB do
      ...>   use TypeWriter
      ...>   deftype String.t
      ...> end
      ...> TypewriterTest.ProductCodeB.__info__(:module)
      TypewriterTest.ProductCodeB

  Both examples generate the following code:

      defmodule ProductCode do
        @enforce_keys [:value]
        defstruct [:value]
        @type t :: %__MODULE__{value: String.t()}
      end

  ## Discriminated Union

  iex> use TypeWriter
  ...> deftype Nickname :: String.t
  ...> deftype FirstLast :: {String.t, String.t}
  ...> deftype Name :: Nickname.t | FirstLast.t
  ...> TypewriterTest.Name.__info__(:module)
  TypewriterTest.Name

  Example translate to:

      defmodule Name do
        @enforce_keys [:value]
        defstruct value: nil
        @type t :: %__MODULE__{value: Nickname.t | FirstLast.t}
      end

  ## Record Type

      iex> use TypeWriter
      ...> deftype ProductA do
      ...>   code :: ProductCode.t()
      ...>   price :: float()
      ...> end
      ...> TypewriterTest.ProductA.__info__(:module)
      TypewriterTest.ProductA

      iex> defmodule ProductB do
      ...>   use TypeWriter
      ...>   deftype do
      ...>     code :: ProductCode.t()
      ...>     price :: integer()
      ...>   end
      ...> end
      ...> TypewriterTest.ProductB.__info__(:module)
      TypewriterTest.ProductB

  Both examples generate the following code:

      defmodule Product do
        @enforce_keys [:code, :price]
        defstruct [:code, :price]

        @type t :: %__MODULE__{code: ProductCode.t(), price: integer()}
      end
  """

  import TypeWriter.TypeDefinition

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

  defmodule SingleCaseUnionType do
    @moduledoc """
    Single case union type is used to wrap a primitive.

    https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/
    """
    defstruct [:name, :type]
  end

  defmodule ProductType do
    @moduledoc false

    defstruct [:name, :type]
  end

  defmodule DiscriminatedUnionType do
    @moduledoc false

    defstruct [:name, :types]
  end

  # Record type - module
  # defmodule Product do
  #   deftype do
  #     code :: ProductCode.t()
  #     price :: float()
  #   end
  # end
  #
  # matches: do, ... end
  defmacro deftype(do: {:__block__, _, ast}) do
    current_module = current_module(__CALLER__.module)
    type = record_type(current_module, ast)
    fields = Enum.map(type.fields, & &1.name)
    spec = get_spec(type)

    quote do
      @enforce_keys unquote(fields)
      defstruct unquote(fields)
      @type t :: %__MODULE__{unquote_splicing(spec)}

      def __type__ do
        unquote(Macro.escape(type))
      end
    end
  end

  # Record type - inline
  # deftype Product do
  #   code :: ProductCode.t()
  #   price :: float()
  # end
  #
  # matches: deftype Product do, ... end
  defmacro deftype({:__aliases__, _, [_module]} = ast, do: block) do
    current_module = current_module(__CALLER__.module)
    type = record_type(current_module, ast, block)
    fields = Enum.map(type.fields, & &1.name)
    spec = get_spec(type)

    quote do
      defmodule unquote(Module.concat([__CALLER__.module, type.name])) do
        @enforce_keys unquote(fields)
        defstruct unquote(fields)
        @type t :: %__MODULE__{unquote_splicing(spec)}

        def __type__ do
          unquote(Macro.escape(type))
        end
      end
    end
  end

  # Discriminated Unions and Product Types
  defmacro deftype(ast) do
    current_module = current_module(__CALLER__.module)
    type = get_type(current_module, ast)
    struct_defn = get_struct_defn(type)
    spec = get_spec(type)

    if module_defined?(current_module, type.name) do
      quote do
        unquote(struct_defn)

        def __type__ do
          unquote(Macro.escape(type))
        end
      end
    else
      quote do
        defmodule unquote(Module.concat([__CALLER__.module, type.name])) do
          unquote(struct_defn)
          unquote(spec)

          def __type__ do
            unquote(Macro.escape(type))
          end

          def __spec__ do
            unquote(Macro.to_string(spec))
          end
        end
      end
    end
  end

  defp get_type(module, ast) do
    type = maybe_single_case_union_type(module, ast)
    type = maybe_discriminated_union_type(module, ast, type)
    maybe_product_type(module, ast, type)
  end

  defp get_struct_defn(type) do
    case type do
      %TypeWriter.SingleCaseUnionType{} ->
        quote do
          @enforce_keys [:value]
          defstruct [:value]
        end

      %TypeWriter.ProductType{} ->
        quote do
          @enforce_keys [:value]
          defstruct [:value]
        end

      %TypeWriter.DiscriminatedUnionType{} ->
        quote do
          @enforce_keys [:value]
          defstruct [:value]
        end
    end
  end

  defp get_spec(type) do
    case type do
      %TypeWriter.RecordType{} = record_type ->
        Enum.map(record_type.fields, fn field ->
          field_name_ast = field.name
          type_ast = elem(field.type, 1)

          quote do
            {unquote(field_name_ast), unquote(type_ast)}
          end
        end)

      %TypeWriter.SingleCaseUnionType{} = union_type ->
        {_, ast} = union_type.type

        quote do
          @type t :: %__MODULE__{value: unquote(ast)}
        end

      %TypeWriter.ProductType{} = product_type ->
        {_, ast} = product_type.type

        quote do
          @type t :: %__MODULE__{value: unquote(ast)}
        end

      %TypeWriter.DiscriminatedUnionType{} ->
        quote do
        end
    end
  end

  # Build the Record type from module syntax
  defp record_type(current_module, ast) do
    fields = Enum.map(ast, &build_field/1)
    %TypeWriter.RecordType{name: current_module, fields: fields}
  end

  # Build the Record type from inline syntax
  defp record_type(
         _current_module,
         {:__aliases__, _, [module]},
         {:__block__, _, ast}
       ) do
    record_type(module, ast)
  end

  defp build_field(
         {:"::", _,
          [
            {name, _, nil},
            type_to_be_wrapped
          ]}
       ) do
    type = from_ast(type_to_be_wrapped)
    %TypeWriter.Field{name: name, type: type}
  end

  # Example: "Single case union type - inline"
  # deftype ProductCode1 :: String.t()
  defp maybe_single_case_union_type(
         _current_module,
         {
           :"::",
           _,
           [{:__aliases__, _, [module]}, {{:., _, [_, _]}, _, _} = type_to_be_wrapped]
         }
       ) do
    %TypeWriter.SingleCaseUnionType{
      name: module,
      type: from_ast(type_to_be_wrapped)
    }
  end

  # Example: "Single case union type - module, alias type"
  # defmodule ProductCode2 do
  #   use TypeWriter
  #
  #   deftype String.t()
  # end
  defp maybe_single_case_union_type(
         current_module,
         {{:., _, [_, _]}, _, []} = type_to_be_wrapped
       ) do
    %TypeWriter.SingleCaseUnionType{
      name: current_module,
      type: from_ast(type_to_be_wrapped)
    }
  end

  # Example: "Single case union type - module, basic type"
  # defmodule ProductCode2 do
  #   use TypeWriter
  #
  #   deftype binary
  # end
  defp maybe_single_case_union_type(
         _current_module,
         {:"::", _,
          [
            {:__aliases__, _, [module]},
            {_basic_type, _, nil} = type_to_be_wrapped
          ]}
       ) do
    %TypeWriter.SingleCaseUnionType{
      name: module,
      type: from_ast(type_to_be_wrapped)
    }
  end

  # Example: "Single case union type - module, basic type, multi-line AST"
  # This can occur with a basic type such as a function
  # defmodule ProductCode2 do
  #   use TypeWriter
  #
  #   deftype binary
  # end

  defp maybe_single_case_union_type(
         _current_module,
         {:"::", _,
          [
            {:__aliases__, _, [module]},
            [_] = type_to_be_wrapped
          ]}
       ) do
    %TypeWriter.SingleCaseUnionType{
      name: module,
      type: from_ast(type_to_be_wrapped)
    }
  end

  defp maybe_single_case_union_type(_current_module, _ast), do: :none
  # defp maybe_single_case_union_type(current_module, ast) do
  #   IO.inspect(ast, label: current_module)
  #   :none
  # end

  # module
  defp maybe_discriminated_union_type(
         current_module,
         {:|, _, union_types},
         _type
       ) do
    types = union_types |> Enum.map(&from_ast/1) |> List.flatten()

    %TypeWriter.DiscriminatedUnionType{
      name: current_module,
      types: types
    }
  end

  # inline
  defp maybe_discriminated_union_type(
         _current_module,
         {:"::", _,
          [
            {:__aliases__, _, [module]},
            {:|, _, union_types}
          ]},
         :none
       ) do
    types = union_types |> Enum.map(&from_ast/1) |> List.flatten()

    %TypeWriter.DiscriminatedUnionType{
      name: module,
      types: types
    }
  end

  defp maybe_discriminated_union_type(_current_module, _ast, type), do: type

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
    type_info = from_ast(product_types)

    %TypeWriter.ProductType{
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
    type_info = from_ast(product_types)

    %TypeWriter.ProductType{
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
