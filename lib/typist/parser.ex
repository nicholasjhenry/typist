defmodule Typist.Parser do
  # Parses Elixir's AST and generates a simplified version of the AST that
  # is easier to generate code for.
  #
  def parse(ast) do
    case perform(ast) do
      # Apply any hanging param to a union function
      {param_2, {:|, _metadata, [param_1]}} ->
        {:|, [], [param_1, param_2]}

      type ->
        type
    end
  end

  # Parse record
  defp perform({:__block__, _, fields_ast}) when is_list(fields_ast) do
    record(fields_ast)
  end

  # Parse union containing aliases
  # e.g. Qux :: integer | Baz :: boolean | Zoo :: term
  defp perform(
         {:"::", _,
          [
            {:|, _,
             [
               previous_aliased_type_ast,
               {:__aliases__, __meta_data, _module_name} = alias_type_ast
             ]},
            remaining_ast
          ]}
       ) do
    previous_aliased_type = perform(previous_aliased_type_ast)
    alias_type = perform(alias_type_ast)

    case perform(remaining_ast) do
      {second_param, {:|, _, [current_aliased_type]}} ->
        {
          {:|, [], [{:"::", [], [alias_type, current_aliased_type]}, second_param]},
          {:|, [], [previous_aliased_type]}
        }

      current_aliased_type ->
        {{:"::", [], [alias_type, current_aliased_type]}, {:|, [], [previous_aliased_type]}}
    end
  end

  # Parse union containing mix of aliases and remote/basic types
  # e.g. integer | boolean | any | Foo.t() :: number | Bar.t() :: term
  defp perform({:"::", _, [{:|, _, [param_1_ast, param_2_ast]}, remaining_ast]}) do
    union(param_2_ast, param_1_ast, remaining_ast)
  end

  # Parse union with remote basic types only
  # e.g. integer | boolean | any | Foo.t() :: number | Bar.t() :: term
  defp perform({:|, _, args}) do
    args = Enum.map(args, &perform(&1))
    {:|, [], args}
  end

  # Parse inline union with multiple aliases
  # e.g. deftype ContactInfo, do: EmailOnly :: EmailContactInfo.t() | PostOnly :: PostContactInfo.t()
  defp perform(
         {:"::", _,
          [
            {:__aliases__, __meta_data, _module_name} = alias_type_ast,
            {:"::", _, _} = remaining_ast
          ]}
       ) do
    alias_type = perform(alias_type_ast)

    case perform(remaining_ast) do
      {second_param, {:|, _, [aliased_type]}} ->
        {:|, [],
         [
           {:"::", [], [alias_type, aliased_type]},
           second_param
         ]}

      second_param ->
        {:|, [],
         [
           {:"::", [], [alias_type, second_param]}
         ]}
    end
  end

  # Parse an alias
  # e.g. Foo.t() :: integer
  defp perform({:"::", _, [{:__aliases__, _, _}, _] = args}) do
    args = Enum.map(args, &perform(&1))
    {:"::", [], args}
  end

  # Parse a type
  # e.g. Foo.t()
  defp perform({{:., _, [{:__aliases__, _metadata, module_name}, :t]}, _, _}) do
    {module_name, :t}
  end

  # Parse a module name
  # e.g. Foo
  defp perform({:__aliases__, _metadata, module_name}) do
    {module_name, :t}
  end

  # Parse a function
  defp perform([{:->, _, [input, output]}]) do
    {:->, [], [Enum.map(input, &perform/1)], perform(output)}
  end

  # Parse basic types
  defp perform({type, _, _})
       when type in [:boolean, :integer, :term, :any, :number, :pid, :binary] do
    type
  end

  # Parse a product type
  # e.g. {integer, Foo.t(), boolean}
  defp perform(product_type) when is_tuple(product_type) do
    params =
      product_type
      |> Tuple.to_list()
      |> Enum.map(&perform/1)

    {:product, [], params}
  end

  ## Handle aliasing in Union types

  defp union(
         {:|, _,
          [
            param_1_ast,
            {:__aliases__, _, _module_name} = param_2_ast
          ]},
         type_ast,
         remaining_ast
       ) do
    case perform(remaining_ast) do
      {second_param, {:|, _, [aliased_type]}} ->
        param_1 = perform(type_ast)
        param_2 = union(param_1_ast, param_2_ast, aliased_type, second_param)
        {:|, [], [param_1, param_2]}
    end
  end

  defp union(
         {:|, _, [params_1_ast, params_2_ast]},
         type_ast,
         remaining_ast
       ) do
    param_1 = perform(type_ast)
    param_2 = union(params_2_ast, params_1_ast, remaining_ast)
    {:|, [], [param_1, param_2]}
  end

  defp union(type_ast, alias_type_ast, aliased_type, second_param) do
    param_1 = perform(type_ast)
    alias_type = perform(alias_type_ast)

    foo = {:"::", [], [alias_type, aliased_type]}
    param_2 = {:|, [], [foo, second_param]}

    {:|, [], [param_1, param_2]}
  end

  defp record(fields_ast) do
    {:record, [], Enum.map(fields_ast, &fields/1)}
  end

  defp fields({:"::", _, [{key, _, _}, type_ast]}) do
    {key, perform(type_ast)}
  end
end
