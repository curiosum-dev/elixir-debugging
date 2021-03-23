defmodule Hello.Pry do
  defmacro peek(arg) do
    quote do
      require IEx
      var!(__arg__) = unquote(arg)
      IEx.pry()
      unquote(arg)
    end
  end
end
