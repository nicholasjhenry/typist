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
  alias Typist.{Generator, Parser}

  defmodule Metadata do
    defstruct ast: nil, calling_module: nil, spec: nil, constructor: nil
  end

  defmacro __using__(_opts \\ []) do
    quote do
      import Typist
    end
  end

  # inline block i.e. record, union
  defmacro deftype(ast, do: block) do
    type(__CALLER__.module, ast, block)
  end

  # block only i.e. record, union
  defmacro deftype(do: block) do
    type(__CALLER__.module, block)
  end

  # module or inline without block, i.e. union (including single), product
  defmacro deftype(ast) do
    type(__CALLER__.module, ast)
  end

  defp type(calling_module, module_ast, block_ast) do
    module = Parser.parse(module_ast)
    fields = Parser.parse(block_ast)
    metadata = %Metadata{ast: fields, calling_module: calling_module}

    Generator.generate(module, metadata)
  end

  defp type(calling_module, ast) do
    ast = Parser.parse(ast)
    metadata = %Metadata{ast: ast, calling_module: calling_module}

    Generator.generate(metadata)
  end
end
