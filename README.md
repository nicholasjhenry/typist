# Typewriter

A DSL to define types inspired by libraries such as TypedStruct and Algae.

STATUS: This is a work in progress. Do not use in production.

## Examples

Types
- module name
  - define module (i.e. within a module)
  - without (i.e. without a module) i.e. `deftype NewType :: a_predefined_type`
- block
  - define on a single line
  - define in a block
    - define a field `new_field :: a_predefined_type`
      opaque: true


# aka wrapper

ProductCode.__type__()

%SingleCaseUnionType{
  name: ProductCode,
  type: "String.t()"
}

```elixir
defmodule MyApp do
  # Example: "Single case union type"
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

  # Example: Record
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

  # Example: Record with defaults

  deftype Product do
    code :: ProductCode.t(), \\ ProductCode.new("ABC123")
    price :: float()
  end    

  defmodule Product do
    @enforce_keys [:code, :price]
    defstruct code: nil, price: ProductCode.new("ABC123")

    @type t :: %__MODULE__{code: ProductCode.t, price: float()}
  end

  # Example: Discriminated union

  deftype MeasurementUnit :: Cm | Inch | Mile

  # translates to:
  defmodule MeasurementUnit do
    @type t :: Cm | Inch | Mile
  end

  # Example: Discriminated union

  deftype Nickname :: String.t
  deftype FirstLast :: {String.t, String.t}
  deftype Name :: Nickname.t | FirstLast.t

  defmodule Name do
    @enforce_keys [:value]
    defstruct value: nil

    @type t :: %__MODULE__{value: Nickname.t | FirstLast.t}
  end
end
```
