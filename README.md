# Typewriter

A DSL to define types inspired by libraries such as TypedStruct and Algae.

STATUS: This is a work in progress. Do not use in production.

## Examples

```elixir
defmodule MyApp do
  # "single case union type"
  deftype ProductCode :: String.t

  # or

  defmodule ProductCode do
    deftype String.t
  end

  # translates to:
  defmodule ProductCode do
    @enforce_keys [:value]
    defstruct value: nil
    @type t :: %__MODULE__{value: String.t}
  end

  # record
  deftype Product do
    code :: ProductCode.t()
    price :: float()
  end    

  defmodule Product do
    deftype do
      code :: ProductCode.t()
      price :: float()
    end
  end    

  # translates to:
  defmodule Product do
    @enforce_keys [:code, :price]
    defstruct code: nil, price: nil

    @type t :: %__MODULE__{code: ProductCode.t, price: float()}
  end

  deftype Product do
    code :: ProductCode.t()
    price :: float()
  end    

  # translates to:
  defmodule Product do
    @enforce_keys [:code, :price]
    defstruct code: nil, price: nil

    @type t :: %__MODULE__{code: ProductCode.t, price: float()}
  end

  deftype Product do
    code :: ProductCode.t(), \\ ProductCode.new("ABC123")
    price :: float()
  end    

  defmodule Product do
    @enforce_keys [:code, :price]
    defstruct code: nil, price: ProductCode.new("ABC123")

    @type t :: %__MODULE__{code: ProductCode.t, price: float()}
  end

  # discriminated union
  deftype MeasurementUnit :: Cm | Inch | Mile

  # translates to:
  defmodule MeasurementUnit do
    @type t :: Cm | Inch | Mile
  end

  deftype Nickname :: String.t
  deftype FirstLast :: {String.t, String.t}
  deftype Name :: Nickname | FirstLast

  # or
  deftype Name :: Nickname of String.t | FirstLast of String.t

  defmodule Name do
    @enforce_keys [:value]
    defstruct value: nil

    @type t :: %__MODULE__{value: Nickname.t | FirstLast.t}
  end
end
```
