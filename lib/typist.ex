defmodule Typist do
  @moduledoc """
  Documentation for Typist.
  """
  alias Typist.{Generator, Parser}

  defmacro __using__(_opts \\ []) do
    quote do
      import Typist
    end
  end

  # Inline record
  defmacro deftype(ast, do: block) do
    record(__CALLER__.module, ast, block)
  end

  # Module record
  defmacro deftype(do: block) do
    type(__CALLER__.module, block)
  end

  # Union and product types (inline or module)
  defmacro deftype(ast) do
    type(__CALLER__.module, ast)
  end

  defp record(calling_module, module_ast, block_ast) do
    module = Parser.parse(module_ast)
    fields = Parser.parse(block_ast)
    metadata = %{ast: fields}

    Generator.build(calling_module, module, metadata)
  end

  defp type(calling_module, ast) do
    ast = Parser.parse(ast)
    metadata = %{ast: ast}

    Generator.build(calling_module, metadata)
  end
end
