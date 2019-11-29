defmodule Typist.Generator do
  alias Typist.Code

  # Generate for a DO-BLOCK
  # e.g. deftype Foo do: price :: integer
  def generate(module_ast, %Typist.Metadata{} = metadata) do
    perform_do_block(module_ast, metadata)
  end

  # Generate for INLINE or MODULE
  def generate(%Typist.Metadata{} = metadata) do
    perform(metadata, metadata.ast)
  end

  # Generate for UNION
  # i.e. {:|, _, _}
  def perform_do_block(module_ast, %{ast: {:|, _, params}} = metadata) do
    new_code =
      metadata
      |> Code.union(metadata.ast)
      |> Code.module(metadata, module_ast)

    [new_code | perform(metadata, params)]
  end

  # Generate for RECORD
  def perform_do_block(module_ast, %{ast: {:record, _, _}} = metadata) do
    {_, _, fields} = metadata.ast

    new_code =
      metadata
      |> Code.record(metadata.ast)
      |> Code.module(metadata, module_ast)

    [new_code | perform(metadata, fields)]
  end

  # Generate for RECORD (module only)
  def perform(%{ast: {:record, _, _} = ast} = metadata, ast) do
    {_, _, fields} = ast
    new_code = Code.record(metadata, ast)

    [new_code | perform(metadata, fields)]
  end

  # Generate for PRODUCT (root)
  def perform(%{ast: ast} = metadata, {:product, _, params} = ast) do
    new_code = Code.product(metadata, ast)

    [new_code | perform(metadata, params)]
  end

  # Generate for PRODUCT (embedded)
  def perform(metadata, {:product, _, params}) do
    perform(metadata, params)
  end

  # Generate for a UNION type (root)
  def perform(%{ast: {:|, _, _} = ast} = metadata, {_, _, params} = ast) do
    new_code = Code.union(metadata, ast)
    [new_code | perform(metadata, params)]
  end

  # Generate for a UNION type (embedded)
  def perform(metadata, {:|, _, params}) do
    perform(metadata, params)
  end

  # Generate for aliases for a UNION type
  def perform(metadata, {:"::", _, [module_ast, {:|, _, params} = ast]}) do
    new_code =
      metadata
      |> Code.union(ast)
      |> Code.module(metadata, module_ast)

    [new_code | perform(metadata, params)]
  end

  # Generate for aliases for a NON-UNION type
  def perform(metadata, {:"::", _, [module_ast, ast]}) do
    new_code =
      metadata
      |> Code.single_case_union(ast)
      |> Code.module(metadata, module_ast)

    [new_code]
  end

  # Generate for SINGLE-CASE UNION type
  def perform(%{ast: {_, :t}} = metadata, {_, :t} = term) do
    [Code.single_case_union(metadata, term)]
  end

  def perform(metadata, [head | tail]) do
    [perform(metadata, head) | perform(metadata, tail)]
  end

  def perform(_metadata, _ast) do
    []
  end
end
