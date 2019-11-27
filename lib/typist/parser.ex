defmodule Typist.Parser do
  def parse(ast) do
    case perform(ast) do
      # Apply any remaining param to the function
      {param_2, {:|, _metadata, [param_1]}} ->
        {:|, [], [param_1, param_2]}

      type ->
        type
    end
  end

  # Generate AST for record
  defp perform({:__block__, _, fields_ast}) when is_list(fields_ast) do
    {:record, [], Enum.map(fields_ast, &fields/1)}
  end

  # Alias within a Union
  defp perform(
         {:"::", _,
          [
            {:|, _,
             [
               previous_aliased_type_ast,
               {:__aliases__, __meta_data, [_module_name]} = alias_type_ast
             ]},
            remaining_ast
          ]}
       ) do
    # e.g. {:integer, [], MyApp}
    previous_aliased_type = perform(previous_aliased_type_ast)
    # e.g. {:__aliases__, [alias: false], [:Baz]}
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

  # e.g. Handle a mix of union types, e.g. integer | boolean | any | Foo.t() :: number | Bar.t() :: term
  defp perform({:"::", _, [{:|, _, [param_1_ast, param_2_ast]}, remaining_ast]}) do
    perform(param_2_ast, param_1_ast, remaining_ast)
  end

  defp perform({:|, _, args}) do
    args = Enum.map(args, &perform(&1))
    {:|, [], args}
  end

  defp perform(
         {:"::", _,
          [
            {:__aliases__, __meta_data, [_module_name]} = alias_type_ast,
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

  # Handle aliasing e.g. Foo.t() :: integer
  defp perform({:"::", _, [{:__aliases__, _, [_]}, _] = args}) do
    args = Enum.map(args, &perform(&1))
    {:"::", [], args}
  end

  # Handle an alias, e.g. Foo.t()
  defp perform({{:., _, [{:__aliases__, _metadata, [module_name]}, :t]}, _, _}) do
    {module_name, :t}
  end

  # Handle an alias, e.g. Foo
  defp perform({:__aliases__, _metadata, [module_name]}) do
    {module_name, :t}
  end

  defp perform([{:->, _, [input, output]}]) do
    {:->, [], [Enum.map(input, &perform/1)], perform(output)}
  end

  # Handle basic types
  defp perform({type, _, _})
       when type in [:boolean, :integer, :term, :any, :number, :pid, :binary] do
    type
  end

  # Handle product type, e.g. {integer, Foo.t(), boolean}
  defp perform(product_type) when is_tuple(product_type) do
    params =
      product_type
      |> Tuple.to_list()
      |> Enum.map(&perform/1)

    {:product, [], params}
  end

  # Handle aliasing in Union types

  defp perform(
         {:|, _,
          [
            param_1_ast,
            {:__aliases__, _, [_module_name]} = param_2_ast
          ]},
         type_ast,
         remaining_ast
       ) do
    case perform(remaining_ast) do
      {second_param, {:|, _, [aliased_type]}} ->
        param_1 = perform(type_ast)
        param_2 = perform(param_1_ast, param_2_ast, aliased_type, second_param)
        {:|, [], [param_1, param_2]}
    end
  end

  defp perform(
         {:|, _, [params_1_ast, params_2_ast]},
         type_ast,
         remaining_ast
       ) do
    param_1 = perform(type_ast)
    param_2 = perform(params_2_ast, params_1_ast, remaining_ast)
    {:|, [], [param_1, param_2]}
  end

  defp perform(type_ast, alias_type_ast, aliased_type, second_param) do
    param_1 = perform(type_ast)
    alias_type = perform(alias_type_ast)

    foo = {:"::", [], [alias_type, aliased_type]}
    param_2 = {:|, [], [foo, second_param]}

    {:|, [], [param_1, param_2]}
  end

  defp fields({:"::", _, [{key, _, _}, type_ast]}) do
    {key, perform(type_ast)}
  end
end
