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
      ...> end
      ...> product_code = Example1.ProductCode.new("ABC")
      ...> product_code.value == "ABC"
      true

      iex> defmodule ProductCode do
      ...>   use Typist
      ...>   deftype String.t
      ...> end
      ...> product_code = ProductCode.new("ABC")
      ...> product_code.value == "ABC"
      true

  Both examples generate the following code:

      defmodule ProductCode do
        @enforce_keys [:value]
        defstruct [:value]
        @type t :: %__MODULE__{value: String.t()}

        @spec new(String.t) :: t
        def new(value) do
          struct!(__MODULE__, value)
        end
      end

  ## Discriminated Unions

  Create new types by “summing” existing types.

  See: [Discriminated Unions](https://fsharpforfunandprofit.com/posts/discriminated-unions/)

  iex> defmodule Example2 do
  ...>   use Typist
  ...>   deftype Nickname :: String.t
  ...>   deftype FirstLast :: {String.t, String.t}
  ...>   deftype Name :: Nickname.t | FirstLast.t
  ...>   def first_last(first, last) do
  ...>     Example2.Name.new({first, last})
  ...>   end
  ...>   def name(value) do
  ...>     Example2.Name.new(value)
  ...>   end
  ...> end
  ...> Example2.first_last("Steve", "Jobs") |> Example2.name
  {"Steve", "Jobs"}

  Example translate to:

      defmodule Name do
        @enforce_keys [:value]
        defstruct value: nil
        @type t :: Nickname.t | FirstLast.t

        @spec new(Nickname.t | FirstLast.t) :: t
        def new(value) do
          value
        end
      end

  ## Product Type

  Creating new types by “multiplying” existing types together.

  From: https://fsharpforfunandprofit.com/posts/designing-with-types-intro/

  > Guideline: Use records or tuples (product type) to group together data that are required to
  > be consistent (that is “atomic”) but don’t needlessly group together data that is not related.

  Example:

      iex> defmodule Example3 do
      ...>   use Typist
      ...>   deftype Product :: {String.t, integer()}
      ...> end
      ...> product = Example3.Product.new({"ABC", 10_00})
      ...> match?(%{value: {"ABC", 10_00}}, product)
      true

  ## Record Type

      iex> defmodule Example4 do
      ...>   use Typist
      ...>   deftype ProductCode :: String.t
      ...>   deftype Product do
      ...>     code :: ProductCode.t()
      ...>     price :: integer()
      ...>   end
      ...>   def product(product_code, price) do
      ...>     %Example4.Product{code: product_code, price: price}
      ...>   end
      ...> end
      ...> product_code = Example4.ProductCode.new("ABC")
      ...> product = Example4.Product.new(%{code: product_code, price: 10_00})
      ...> match?(%{code: %{value: "ABC"}, price: 10_00}, product)
      true

      iex> defmodule Product do
      ...>   use Typist
      ...>   deftype ProductCode :: String.t
      ...>   deftype do
      ...>     code :: ProductCode.t()
      ...>     price :: integer()
      ...>   end
      ...> end
      ...> product_code = Product.ProductCode.new("ABC")
      ...> product = Product.new(%{code: product_code, price: 10_00})
      ...> match?(%{code: %{value: "ABC"}, price: 10_00}, product)
      true

  Both examples generate the following code:

      defmodule Product do
        @enforce_keys [:code, :price]
        defstruct [:code, :price]

        @type t :: %__MODULE__{code: ProductCode.t(), price: integer}

        @spec new(%{code: ProductCode.t(), price: integer}) :: t
        def new(fields) do
          struct!(__MODULE__, fields)
        end
      end
  """
  alias Typist.Code

  defmodule Type do
    defstruct spec: [], constructor: []
  end

  defmacro __using__(_opts) do
    quote do
      import Typist
    end
  end

  defmacro deftype(ast, do: block) do
    type(__CALLER__.module, ast, block)
  end

  defmacro deftype(block) do
    type(__CALLER__.module, block)
  end

  def type_code(type) do
    quote location: :keep do
      def __type__ do
        unquote(
          Macro.escape(%{
            type
            | spec: Macro.to_string(type.spec),
              constructor: Macro.to_string(type.constructor)
          })
        )
      end
    end
  end

  # Define a record type inline
  defp type(caller_module, {:__aliases__, _metadata, module_name}, block) do
    caller_module
    |> type(do: block)
    |> Code.module(caller_module, module_name)
  end

  # Define a record type in module
  defp type(_caller_module, do: block) do
    spec = Code.to_spec(block)
    struct = Code.to_struct(block)

    fields = Code.to_fields(block)

    constructor =
      quote do
        @spec new(%{unquote_splicing(fields)}) :: t
      end

    type = %Type{spec: spec, constructor: constructor}

    quote location: :keep do
      unquote(type.spec)
      unquote(struct)
      unquote(type_code(type))

      unquote(type.constructor)
      def new(value), do: struct!(__MODULE__, value)
      defoverridable new: 1
    end
  end

  # Define a discriminated union type inline
  defp type(caller_module, {:"::", _, [{:__aliases__, _, module_name}, {:|, _, _} = type]}) do
    caller_module
    |> type(type)
    |> Code.module(caller_module, module_name)
  end

  # Define a discriminated union type inside module
  defp type(_caller_module, {:|, _, _} = type) do
    spec =
      quote do
        @type t :: unquote(type)
      end

    constructor =
      quote do
        @spec new(unquote(type)) :: t
      end

    type = %Type{spec: spec, constructor: constructor}

    quote do
      unquote(type.spec)
      unquote(type.constructor)
      def new(value), do: value
      defoverridable new: 1

      unquote(type_code(type))
    end
  end

  # Define a single case union type inline
  defp type(caller_module, {:"::", _, [{:__aliases__, _, module_name}, type]}) do
    caller_module
    |> type(type)
    |> Code.module(caller_module, module_name)
  end

  # Define a single case union or product type inside module
  defp type(_caller_module, typex) do
    spec =
      quote do
        @type t :: %__MODULE__{value: unquote(typex)}
      end

    constructor =
      quote do
        @spec new(unquote(typex)) :: t
      end

    type = %Type{spec: spec, constructor: constructor}

    quote do
      defimpl Inspect do
        import Inspect.Algebra

        def inspect(struct, opts) do
          display =
            if String.Chars.impl_for(struct.value) do
              to_string(struct.value)
            else
              inspect(struct.value)
            end

          concat(["#", to_doc(@for, opts), "<", display, ">"])
        end
      end

      unquote(type.spec)
      defstruct [:value]

      unquote(type.constructor)
      def new(value), do: struct!(__MODULE__, value: value)

      unquote(type_code(type))

      @spec apply(t, (unquote(typex) -> any)) :: any
      def apply(%__MODULE__{} = wrapper, func) do
        func.(wrapper.value)
      end

      @spec value(t) :: unquote(typex)
      def value(%__MODULE__{} = wrapper) do
        wrapper.value
      end

      defoverridable new: 1
    end
  end

  defmacro defunion(ast, block) do
    union(__CALLER__.module, ast, block)
  end

  defp union(caller_module, {:__aliases__, _metadata, module_name}, do: block) do
    types = types(caller_module, block)
    spec = union_spec(block)

    constructor =
      quote do
        @spec new(unquote(spec)) :: t
      end

    spec =
      quote do
        @type t :: unquote(spec)
      end

    type = %Type{spec: spec, constructor: constructor}

    content =
      quote do
        unquote(type.spec)
        unquote(type.constructor)
        def new(value), do: value
        defoverridable new: 1
        unquote(type_code(type))
      end

    Code.module(content, caller_module, module_name, types)
  end

  defp types(caller_module, {:__block__, _, ast}) do
    Enum.map(ast, &type(caller_module, &1))
  end

  defp union_spec({:__block__, _, ast}) do
    ast
    |> Enum.map(&union_spec/1)
    |> union_spec
  end

  defp union_spec({:"::", _, [type, _]}) do
    quote do
      unquote(type).t
    end
  end

  defp union_spec([head, tail]) do
    {:|, [], [head, tail]}
  end

  defp union_spec([head | tail]) do
    {:|, [], [head, union_spec(tail)]}
  end
end
