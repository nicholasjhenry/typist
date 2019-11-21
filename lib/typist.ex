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

  ## Discriminated Union

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
  ...> name = Example2.first_last("Steve", "Jobs") |> Example2.name
  ...> {"Steve", "Jobs"} == name.value.value
  true

  Example translate to:

      defmodule Name do
        @enforce_keys [:value]
        defstruct value: nil
        @type t :: %__MODULE__{value: Nickname.t | FirstLast.t}

        @spec new(Nickname.t | FirstLast.t) :: t
        def new(value) do
          struct!(__MODULE__, value: value)
        end
      end

  ## Record Type

      iex> defmodule Example3 do
      ...>   use Typist
      ...>   deftype ProductCode :: String.t
      ...>   deftype Product do
      ...>     code :: ProductCode.t()
      ...>     price :: integer()
      ...>   end
      ...>   def product(product_code, price) do
      ...>     %Example3.Product{code: product_code, price: price}
      ...>   end
      ...> end
      ...> product_code = Example3.ProductCode.new("ABC")
      ...> product = Example3.Product.new(%{code: product_code, price: 10_00})
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

  defmacro __using__(_opts) do
    quote do
      import Typist
    end
  end

  alias Typist.{DiscriminatedUnionType, ProductType, RecordType, SingleCaseUnionType}

  # __CALLER__: See https://hexdocs.pm/elixir/Macro.Env.html
  # module_path: The full qualified path of a module e.g. `Foo.Bar.Baz`
  # module_name: The name of the module without the path e.g. `Baz`

  defmacro deftype(ast, do: block) do
    maybe_build(__CALLER__.module, ast, block)
  end

  defmacro deftype(do: block) do
    maybe_build(__CALLER__.module, :none, block)
  end

  defmacro deftype(ast) do
    maybe_build(__CALLER__.module, ast, :none)
  end

  defp maybe_build(module, ast, block) do
    RecordType.maybe_build(module, ast, block)
    |> if_none(&SingleCaseUnionType.build(module, ast, &1))
    |> if_none(&DiscriminatedUnionType.build(module, ast, &1))
    |> if_none(&ProductType.build(module, ast, &1))
  end

  defp if_none(:none, func), do: func.(:none)
  defp if_none(result, _func), do: result
end
