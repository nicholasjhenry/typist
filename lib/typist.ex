defmodule Typist do
  @moduledoc """
  Documentation for Typist.
  """
  alias Typist.{Generator, Parser}

  defmodule Metadata do
    defstruct ast: nil, calling_module: nil, spec: nil
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

    code = Generator.generate(module, metadata)

    quote do
      unquote({:__block__, [], code})
    end
  end

  defp type(calling_module, ast) do
    ast = Parser.parse(ast)
    metadata = %Metadata{ast: ast, calling_module: calling_module}

    code = Generator.generate(metadata)

    quote do
      unquote({:__block__, [], code})
    end
  end
end
