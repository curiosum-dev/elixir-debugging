defmodule Hello.Pry do
  defmacro peek(arg) do
    quote do
      var!(__arg__) = unquote(arg)
      IEx.pry()
      unquote(arg)
    end
  end

  defmacro next() do
    quote do
      IO.inspect(__MODULE__)

      {current_function_name, arity} = __ENV__.function

      IEx.break!(
        __MODULE__,
        current_function_name,
        arity
      )
    end
  end
end
