defmodule Hello do
  @moduledoc """
  Hello keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  require Hello.Pry

  def process() do
    x = 1

    12345
    |> Integer.to_string()
    |> String.reverse()
    |> Hello.Pry.peek()
    |> String.to_integer()
    |> Hello.Pry.peek()
  end
end
