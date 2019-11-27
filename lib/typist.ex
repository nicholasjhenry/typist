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

  # inline block e.g. record
  defmacro deftype(ast, do: block) do
    type(__CALLER__.module, ast, block)
  end

  # block only e.g. record
  defmacro deftype(do: block) do
    type(__CALLER__.module, block)
  end

  # module or inline without block
  defmacro deftype(ast) do
    type(__CALLER__.module, ast)
  end

  defp type(calling_module, module_ast, block_ast) do
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
