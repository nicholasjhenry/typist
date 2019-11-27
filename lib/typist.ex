defmodule Typist do
  @moduledoc """
  Documentation for Typist.
  """
  alias Typist.{Generator, Parser}

  defmodule Metadata do
    defstruct ast: nil, calling_module: nil, remaining_ast: nil, code: []
  end

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
    metadata = %Metadata{ast: fields, calling_module: calling_module, remaining_ast: fields}

    code = Generator.build(module, metadata, [])

    quote do
      unquote({:__block__, [], code})
    end
  end

  defp type(calling_module, ast) do
    ast = Parser.parse(ast)
    metadata = %Metadata{ast: ast, calling_module: calling_module, remaining_ast: ast}

    code = Generator.build(metadata, [])

    quote do
      unquote({:__block__, [], code})
    end
  end
end
