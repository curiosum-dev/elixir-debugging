:ets.new(:precise_pry, [:set, :public, :named_table])

defmodule PrecisePry.Helpers do
  require IEx

  def next do
    IEx.Helpers.continue()
  end

  def resume do
    :ets.insert(:precise_pry, {"enabled", false})
    IEx.Helpers.continue()
  end

  defmacro maybe_pry do
    quote do
      case :ets.lookup(:precise_pry, "enabled") do
        [{"enabled", true}] -> IEx.pry()
        _ -> :ok
      end
    end
  end
end

defmodule PrecisePry do
  use SafeOverride, [def: 2, def: 1, defp: 2, defp: 1]
  import Kernel, except: [def: 2, def: 1, defp: 2, defp: 1]
  require IEx

  defmacro __using__(_opts) do
    quote do
      require SafeOverride
      require IEx
      import PrecisePry.Helpers

      SafeOverride.import_code_for(unquote(__MODULE__), [def: 2, def: 1, defp: 2, defp: 1])

      defmacrop pry() do
        quote do
          :ets.insert(:precise_pry, {"enabled", true})
        end
      end
    end
  end

  defmacro def(call, expr \\ nil) do
    {t1, t2, [{function_name, location, args}, [do: {:__block__, context, list}]]} = super(call, expr)

    new_list =
      list
      |> Enum.flat_map(fn item ->
        {expression, location, context} = item
        [line: line] = location
        pry_item = {{:., [line: line], [{:__aliases__, [line: line], [:PrecisePry, :Helpers]}, :maybe_pry]}, [line: line], []}
        [pry_item, item]
      end)

    {
      original_list_prefix,
      [
        original_last_expr
      ]
    } = Enum.split(new_list, -1)

    {_, [line: last_line], _} = original_last_expr

    new_list = Enum.concat(
      original_list_prefix,
      [
        {:=, [line: last_line], [{:__retval__, [line: last_line], Elixir}, original_last_expr]},
        {{:., [line: last_line + 1], [{:__aliases__, [line: last_line + 1], [:PrecisePry, :Helpers]}, :maybe_pry]}, [line: last_line + 1], []},
        {:__retval__, [line: last_line + 1], Elixir}
      ]
    )

    {t1, t2, [{function_name, location, args}, [do: {:__block__, context, new_list}]]}
  end
end


defmodule Example do
  use PrecisePry

  def foo(arg) do
    pry()
    x = arg
    x = x + 1
    x = x + 2
  end

  def bar do
    pry()
    y = 1
    y + 1
  end
end

x = Example.foo(1)
y = Example.bar()
IO.inspect("The result is #{inspect(x)} and #{inspect(y)}")
