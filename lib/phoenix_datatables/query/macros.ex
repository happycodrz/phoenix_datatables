defmodule PhoenixDatatables.Query.Macros do
  @moduledoc false

  defp bind_number(num, name \\ :t) do
    blanks =
    for _ <- 0..num do
      {:_, [], Elixir}
    end
    Enum.drop(blanks, 1) ++ [{name, [], Elixir}]
  end

  defp def_order_relation(num) do
    bindings = bind_number(num)
    quote do
      defp order_relation(queryable, unquote(num), dir, column) do
        order_by(queryable, unquote(bindings), [{^dir, field(t, ^column)}])
      end
    end
  end

  defp def_order_relations(defines_count) do
    for n <- 0..defines_count do
      def_order_relation(n)
    end
  end

  defp def_search_relation(num) do
    bindings = bind_number(num)
    quote do
      defp search_relation(queryable, unquote(num), attribute, search_term) do
        or_where(queryable,
                 unquote(bindings),
                 fragment("CAST(? AS TEXT) ILIKE ?", field(t, ^attribute), ^search_term))
      end
    end
  end

  defp def_search_relations(defines_count) do
    for n <- 0..defines_count do
      def_search_relation(n)
    end
  end

  defmacro __using__(arg) do
    defines_count = case arg do
                      [] -> 25
                      num when is_integer(num) -> num
                      arg -> raise """
                                unknown args #{inspect arg} for
                                PhoenixDatatables.Query.Macros.__using__,
                                provide a number or nothing"
                              """
                    end
    order_relations = def_order_relations(defines_count)
    search_relations = def_search_relations(defines_count)
    quote do
      import PhoenixDatatables.Query.Macros
      unquote(order_relations)
      defp search_relation(queryable, nil, _, _), do: queryable
      unquote(search_relations)
    end
  end

end