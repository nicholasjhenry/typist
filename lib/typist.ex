defmodule Typist do
  @moduledoc """
  A DSL to define types inspired by libraries such as TypedStruct, Algae and the F# language.

  ## Definitions

  * Discriminated union (AKA disjoint union, sum type):
  * Product type (AKA record):

  ## References:

  * [Designing with Types Series](https://fsharpforfunandprofit.com/posts/designing-with-types-intro/)

  ## Single Case Union Type

  See: [Designing with types: Single case union types](https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/)

      iex> defmodule Example1 do
      ...>   use Typist
      ...>   deftype ProductCode :: String.t
      ...>   def product_code(value) do
      ...>     %Example1.ProductCode{value: value}
      ...>   end
      ...> end
      ...> product_code = Example1.product_code("ABC")
      ...> product_code.value == "ABC"
      true

      iex> defmodule ProductCode do
      ...>   use Typist
      ...>   deftype String.t
      ...>   def new(value) do
      ...>     %__MODULE__{value: value}
      ...>   end
      ...> end
      ...> product_code = ProductCode.new("ABC")
      ...> product_code.value == "ABC"
      true

  Both examples generate the following code:

      defmodule ProductCode do
        @enforce_keys [:value]
        defstruct [:value]
        @type t :: %__MODULE__{value: String.t()}
      end

  ## Discriminated Union

  iex> defmodule Example2 do
  ...>   use Typist
  ...>   deftype Nickname :: String.t
  ...>   deftype FirstLast :: {String.t, String.t}
  ...>   deftype Name :: Nickname.t | FirstLast.t
  ...>   def first_last(first, last) do
  ...>     %Example2.FirstLast{value: {first, last}}
  ...>   end
  ...>   def name(value) do
  ...>     %Example2.Name{value: value}
  ...>   end
  ...> end
  ...> name = Example2.first_last("Steve", "Jobs") |> Example2.name
  ...> {"Steve", "Jobs"} == name.value.value
  true

  Example translate to:

      defmodule Name do
        @enforce_keys [:value]
        defstruct value: nil
        @type t :: %__MODULE__{value: Nickname.t | FirstLast.t}
      end

  ## Record Type

      iex> defmodule Example3 do
      ...>   use Typist
      ...>   deftype ProductCode :: String.t
      ...>   deftype Product do
      ...>     code :: ProductCode.t()
      ...>     price :: integer()
      ...>   end
      ...>   def product_code(value) do
      ...>     %Example3.ProductCode{value: value}
      ...>   end
      ...>   def product(product_code, price) do
      ...>     %Example3.Product{code: product_code, price: price}
      ...>   end
      ...> end
      ...> product = Example3.product_code("ABC") |> Example3.product(10_00)
      ...> match?(%{code: %{value: "ABC"}, price: 10_00}, product)
      true

      iex> defmodule Product do
      ...>   use Typist
      ...>   deftype ProductCode :: String.t
      ...>   deftype do
      ...>     code :: ProductCode.t()
      ...>     price :: integer()
      ...>   end
      ...>   def product_code(value) do
      ...>     %Product.ProductCode{value: value}
      ...>   end
      ...>   def new(product_code, price) do
      ...>     %Product{code: product_code, price: price}
      ...>   end
      ...> end
      ...> product = Product.product_code("ABC") |> Product.new(10_00)
      ...> match?(%{code: %{value: "ABC"}, price: 10_00}, product)
      true

  Both examples generate the following code:

      defmodule Product do
        @enforce_keys [:code, :price]
        defstruct [:code, :price]

        @type t :: %__MODULE__{code: ProductCode.t(), price: integer()}
      end
  """

  defmacro __using__(_opts) do
    quote do
      import Typist
    end
  end

  alias Typist.{DiscriminatedUnionType, SingleCaseUnionType, RecordType}

  defmodule ProductType do
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
  end

  # Data type: record, module
  #
  # defmodule Product do
  #   deftype do
  #     code :: ProductCode.t()
  #     price :: float()
  #   end
  # end
  #
  # matches: do, ... end
  defmacro deftype(do: {:__block__, _, _} = ast) do
    RecordType.build(__CALLER__, ast)
  end

  # Data type: record, inline
  #
  # deftype Product do
  #   code :: ProductCode.t()
  #   price :: float()
  # end
  #
  # matches: deftype Product do, ... end
  defmacro deftype({:__aliases__, _, [_module]} = ast, do: block) do
    RecordType.build(__CALLER__, ast, block)
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
        unquote(spec)

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
    type = SingleCaseUnionType.maybe_build(module, ast)
    type = DiscriminatedUnionType.maybe_build(module, ast, type)
    maybe_product_type(module, ast, type)
  end

  defp get_struct_defn(type) do
    case type do
      %Typist.SingleCaseUnionType{} ->
        quote do
          @enforce_keys [:value]
          defstruct [:value]
        end

      %Typist.ProductType{} ->
        quote do
          @enforce_keys [:value]
          defstruct [:value]
        end

      %Typist.DiscriminatedUnionType{} ->
        quote do
          @enforce_keys [:value]
          defstruct [:value]
        end
    end
  end

  defp get_spec(type) do
    case type do
      %Typist.SingleCaseUnionType{} = union_type ->
        {_, ast} = union_type.type

        quote do
          @type t :: %__MODULE__{value: unquote(ast)}
        end

      %Typist.ProductType{} = product_type ->
        {_, ast} = product_type.type

        quote do
          @type t :: %__MODULE__{value: unquote(ast)}
        end

      %Typist.DiscriminatedUnionType{} ->
        quote do
        end
    end
  end

  # Data type: product type, inline
  #
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
  defp maybe_product_type(current_module, product_types, :none) do
    type_info = from_ast(product_types)

    %Typist.ProductType{
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

  # Returns the type definition from the AST.
  # For union types, e.g.:
  # `String.t | non_neg_integer | nil`
  defp from_ast({:|, _, types}) do
    Enum.map(types, &from_ast/1)
  end

  defp from_ast(ast) do
    {Macro.to_string(ast), ast}
  end
end
