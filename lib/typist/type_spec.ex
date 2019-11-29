defmodule Typist.TypeSpec do
  def from_ast({module_name, :t}) do
    quote do
      @type t :: %__MODULE__{value: unquote(Module.concat(module_name)).t}
    end
  end

  def from_ast({:basic, _, [term]}) do
    quote do
      @type t :: %__MODULE__{value: unquote(term)}
    end
  end

  def from_ast({:|, _, params}) do
    quote do
      @type t :: unquote({:|, [], do_ast(params)})
    end
  end

  def from_ast({:product, _, params}) do
    quote do
      @type t :: %__MODULE__{value: {unquote_splicing(do_ast(params))}}
    end
  end

  def from_ast({:record, _, fields}) do
    spec = do_fields(fields)

    quote do
      @type t :: %__MODULE__{unquote_splicing(spec)}
    end
  end

  defp do_fields([head | tail]) do
    [do_fields(head) | do_fields(tail)]
  end

  defp do_fields({key, field}) do
    quote do
      {unquote(key), unquote(do_ast(field))}
    end
  end

  defp do_fields([]) do
    []
  end

  def from_ast(term) do
    quote do
      @type t :: {:not_defined, unquote(Macro.escape(term))}
    end
  end

  defp do_ast([head | tail]) do
    [do_ast(head) | do_ast(tail)]
  end

  defp do_ast({:product, _, params}) do
    params |> Enum.map(&do_ast/1) |> List.to_tuple()
  end

  defp do_ast({:|, _, params}) do
    {:|, [], do_ast(params)}
  end

  defp do_ast({:"::", _, [{aliasing_module, :t}, _aliased]}) do
    quote do
      unquote(Module.concat(aliasing_module)).t()
    end
  end

  defp do_ast({module_name, :t}) do
    quote do
      unquote(Module.concat(module_name)).t()
    end
  end

  defp do_ast({:basic, [], [term]}) do
    {term, [], Elixir}
  end

  defp do_ast(term) when is_atom(term) do
    term
  end

  defp do_ast([]) do
    quote do
      []
    end
  end
end
