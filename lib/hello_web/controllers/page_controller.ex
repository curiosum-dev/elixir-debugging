defmodule HelloWeb.PageController do
  use HelloWeb, :controller

  @spec index(Plug.Conn.t(), nil | maybe_improper_list | map) :: Plug.Conn.t()
  def index(conn, params) do
    result =
      (params["val"] || "0")
      |> String.to_integer()
      |> add(5)
      |> mul(3)
      |> add(77)
      |> mul(121)

    render(conn, "index.html", result: result)
  end

  defp add(val, x) do
    val + x
  end

  defp mul(val, x) do
    val * x
  end
end
