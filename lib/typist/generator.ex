defmodule Typist.Generator do
  alias Typist.Code

  # Generate for a do-block
  # e.g. deftype Foo do: price :: integer
  def generate(module_ast, %Typist.Metadata{} = metadata, code) do
    perform_do_block(module_ast, metadata, code)
  end

  # Generate for inline or module
  def generate(%Typist.Metadata{} = metadata, code) do
    perform(metadata, metadata.ast, code)
  end

  # Generate for inline union
  # i.e. {:|, _, _}
  def perform_do_block(module_ast, %{ast: {:|, _, _}} = metadata, code) do
    new_code =
      metadata
      |> Code.union(metadata.ast)
      |> Code.module(metadata, module_ast)

    [new_code | generate(metadata, code)]
  end

  # Generate for record from block
  def perform_do_block(module_ast, %{ast: {:record, _, _}} = metadata, [] = code) do
    {_, _, fields} = metadata.ast

    new_code =
      metadata
      |> Code.record(metadata.ast)
      |> Code.module(metadata, module_ast)

    [new_code | perform(metadata, fields, code)]
  end

  # Generate for record from module
  def perform(%{ast: {:record, _, _} = ast} = metadata, ast, [] = code) do
    {_, _, fields} = ast
    new_code = Code.record(metadata, ast)

    [new_code | perform(metadata, fields, code)]
  end

  # Generate for aliases for a union type
  def perform(metadata, {:"::", _, [module_ast, {:|, _, _} = ast]}, [] = code) do
    new_code =
      metadata
      |> Code.union(ast)
      |> Code.module(metadata, module_ast)

    [new_code | code]
  end

  # Generate for aliases for a non union type
  def perform(metadata, {:"::", _, [module_ast, ast]}, [] = code) do
    new_code =
      metadata
      |> Code.wrapped_type(ast)
      |> Code.module(metadata, module_ast)

    [new_code | code]
  end

  # Generate for product
  # e.g. {:product, _, _}
  def perform(metadata, {:product, _, params} = ast, code) do
    new_code = Code.wrapped_type(metadata, ast)

    [new_code | perform(metadata, params, code)]
  end

  # Generate for inline or module-based definitions
  def perform(%{ast: {:|, _, _} = ast} = metadata, {_, _, params} = ast, [] = code) do
    new_code = Code.union(metadata, ast)

    [new_code | perform(metadata, params, code)]
  end

  def perform(%{ast: {_, :t}} = metadata, {_, :t} = term, code) do
    new_code = Code.wrapped_type(metadata, term)
    [new_code | code]
  end

  def perform(metadata, [head | tail], code) do
    [perform(metadata, head, code) | perform(metadata, tail, code)]
  end

  def perform(_metadata, _term, code) do
    code
  end
end
