defmodule Hello do
  @moduledoc """
  Hello keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  require Hello.Pry
  require IEx

  def process() do
    IEx.Pry.pry(binding(), __ENV__)

    x = 1

    12345
    |> Integer.to_string()
    |> Hello.Pry.peek()
    |> String.reverse()
    |> Hello.Pry.peek()
    |> String.to_integer()

    # foo(bar)
    # bar(foo)
  end

  Kernel

  def step_test() do

    IEx.pry()
    x = 1
    IO.puts("one")
    y = 2
    IO.puts("two")
    z = 3
    IO.puts(inspect(x + y + z))
  end
end
