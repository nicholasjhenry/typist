defmodule Typist.RecordType do
  @moduledoc """
  A record type, a product type with named fields.

  Example:

      deftype ProductCode :: String.t
      deftype Product do
        code :: ProductCode.t()
        price :: integer()
      end
  """
  defmodule Field do
    @moduledoc """
    A field in a `RecordType`.
    """

    @enforce_keys [:name, :type]
    defstruct [:name, :type]
  end

  @enforce_keys [:name, :spec, :fields, :module_path, :defined, :ast]
  defstruct [:name, :spec, :fields, :module_path, :defined, :ast]

  import Typist.Module

  def maybe_build(module_path, ast, block) do
    module_name = module_name(module_path)

    case maybe_type(module_name, module_path, ast, block) do
      :none ->
        :none

      type ->
        build_ast(type)
    end
  end

  # Data type: record, module
  #
  # defmodule Product do
  #   deftype do
  #     code :: ProductCode.t()
  #     price :: float()
  #   end
  # end
  #
  # matches: do, ... end
  defp maybe_type(type_name, module_path, :none, {:__block__, _, block}) do
    type(type_name, module_path, block, :module)
  end

  # Data type: record, inline
  #
  # deftype Product do
  #   code :: ProductCode.t()
  #   price :: float()
  # end
  #
  # matches: deftype Product do, ... end
  defp maybe_type(
         _module_name,
         module_path,
         {:__aliases__, _, [type_name]},
         {:__block__, _, block}
       ) do
    type(type_name, module_path, block, :inline)
  end

  defp maybe_type(_module_name, _module_path, _ast, _defined), do: :none

  defp type(type_name, module_path, block, defined) do
    fields = Enum.map(block, &build_field/1)

    constructor_spec =
      Enum.map(fields, fn field ->
        %{name: name, type: {_, x}} = field
        {{:required, [], [name]}, x}
      end)

    %Typist.RecordType{
      name: type_name,
      module_path: module_path,
      fields: fields,
      defined: defined,
      spec: spec(fields),
      ast: constructor_spec
    }
  end

  defp build_field(
         {:"::", _,
          [
            {name, _, nil},
            ast
          ]}
       ) do
    %Field{name: name, type: {Macro.to_string(ast), ast}}
  end

  defp spec(fields) do
    field_specs =
      Enum.map(fields, fn field ->
        field_name_ast = field.name
        type_ast = elem(field.type, 1)

        quote do
          {unquote(field_name_ast), unquote(type_ast)}
        end
      end)

    quote do
      @type t :: %__MODULE__{unquote_splicing(field_specs)}
    end
  end

  defp build_ast(type) do
    case type.defined do
      :module ->
        do_build_ast(type)

      :inline ->
        quote do
          defmodule unquote(Module.concat([type.module_path, type.name])) do
            unquote(do_build_ast(type))
          end
        end
    end
  end

  defp do_build_ast(type) do
    fields = Enum.map(type.fields, & &1.name)

    quote do
      @enforce_keys unquote(fields)
      defstruct unquote(fields)
      unquote(type.spec)

      def __type__ do
        unquote(Macro.escape(%{type | spec: Macro.to_string(type.spec)}))
      end

      @spec new(%{unquote_splicing(type.ast)}) :: t
      def new(fields) do
        struct(__MODULE__, fields)
      end
    end
  end
end
