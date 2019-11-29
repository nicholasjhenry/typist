defmodule Typist.Generator do
  alias Typist.Code

  # Generate for a DO-BLOCK
  # e.g. deftype Foo do: price :: integer
  def generate(module_ast, %Typist.Metadata{} = metadata) do
    perform_do_block(module_ast, metadata, [])
  end

  # Generate for INLINE or MODULE
  def generate(%Typist.Metadata{} = metadata) do
    perform(metadata, metadata.ast, [])
  end

  # Generate for UNION
  # i.e. {:|, _, _}
  def perform_do_block(module_ast, %{ast: {:|, _, _}} = metadata, [] = code) do
    new_code =
      metadata
      |> Code.union(metadata.ast)
      |> Code.module(metadata, module_ast)

    [new_code | perform(metadata, metadata.ast, code)]
  end

  # Generate for RECORD
  def perform_do_block(module_ast, %{ast: {:record, _, _}} = metadata, [] = code) do
    {_, _, fields} = metadata.ast

    new_code =
      metadata
      |> Code.record(metadata.ast)
      |> Code.module(metadata, module_ast)

    [new_code | perform(metadata, fields, code)]
  end

  # Generate for RECORD (module only)
  def perform(%{ast: {:record, _, _} = ast} = metadata, ast, [] = code) do
    {_, _, fields} = ast
    new_code = Code.record(metadata, ast)

    [new_code | perform(metadata, fields, code)]
  end

  # Generate for PRODUCT, only wrap for aliased types
  def perform(%{ast: ast} = metadata, {:product, _, params} = ast, code) do
    new_code = Code.product(metadata, ast)

    [new_code | perform(metadata, params, code)]
  end

  def perform(metadata, {:product, _, params}, code) do
    perform(metadata, params, code)
  end

  # Generate for a UNION type
  def perform(%{ast: {:|, _, _} = ast} = metadata, {_, _, params} = ast, [] = code) do
    new_code = Code.union(metadata, ast)

    [new_code | perform(metadata, params, code)]
  end

  # Generate for aliases for a UNION type
  def perform(metadata, {:"::", _, [module_ast, {:|, _, _} = ast]}, [] = code) do
    new_code =
      metadata
      |> Code.union(ast)
      |> Code.module(metadata, module_ast)

    [new_code | code]
  end

  # Generate for aliases for a NON-UNION type
  def perform(metadata, {:"::", _, [module_ast, ast]}, [] = code) do
    new_code =
      metadata
      |> Code.single_case_union(ast)
      |> Code.module(metadata, module_ast)

    [new_code | code]
  end

  # Generate for SINGLE-CASE UNION type
  def perform(%{ast: {_, :t}} = metadata, {_, :t} = term, code) do
    new_code = Code.single_case_union(metadata, term)
    [new_code | code]
  end

  def perform(metadata, [head | tail], code) do
    [perform(metadata, head, code) | perform(metadata, tail, code)]
  end

  def perform(_metadata, _term, code) do
    code
  end
end
