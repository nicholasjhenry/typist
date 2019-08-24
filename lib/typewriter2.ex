defmodule Typewriter2 do
  defmacro __using__(_opts) do
    quote do
      import Typewriter2
    end
  end

  defmacro deftype(ast) do
    ast |> IO.inspect(label: "AST")

    case ast do
      {:"::", [_metadata], lines} ->
        [foo(lines) | [:"::"]]
        |> List.flatten()
        |> Enum.reverse()
        |> Enum.chunk_every(2)
        |> Enum.flat_map(&bar/1)
        |> IO.inspect(label: "complete")

      _ ->
        :foo
    end
  end

  defp foo([line | lines]) do
    [foo(lines) | [foo(line)]]
  end

  defp foo({:__aliases__, _metadata, [type]}) do
    type
  end

  defp foo({:|, _metadata, lines}) do
    [foo(lines) | [:|]]
  end

  defp foo([]), do: []

  defp bar([operator, type]) do
    [type, operator]
  end

  defp bar(type), do: type
end

# ::
# - ThreeState
# - |
#    - Checked
#    - |
#      - Unchecked
#      - Unknown
