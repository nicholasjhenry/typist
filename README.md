# Typist

## About this library

A DSL to define types inspired by libraries such as TypedStruct, Algae and the F# language.

## Documentation

See module documentation for examples.

## Why typist?

Compared to other libraries, Typist is designed to be terse and optimized for wrapping a
single Elixir primitive creating a domain specific primitive, also known as a Value Object
in Domain-Driven Design.

```elixir
# Typist
defmodule Product do
  use Typist

  deftype Code :: String.t
  deftype Price :: Decimal.t

  deftype do
    code :: Product.Code.t
    price :: Product.Price.t
  end
end

# TypedStruct

defmodule Product do
  defmodule Code do
    use TypedStruct

    typedstruct enforce_keys: true do
      field :value, String.t
    end
  end

  defmodule Price do
    use TypedStruct

    typedstruct enforce_keys: true do
      field :value, Decimal.t
    end
  end

  use TypedStruct

  typedstruct do
    field :code, Code.t
    field :price, Price.t
  end
end
```

## About CivilCode Inc

CivilCode Inc. is a [custom software development](https://www.civilcode.io) studio developing tailored business applications in [Elixir](http://elixir-lang.org/) and [Phoenix](http://www.phoenixframework.org/) in Montreal, Canada.
