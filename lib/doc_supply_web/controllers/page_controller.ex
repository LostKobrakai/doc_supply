defmodule DocSupplyWeb.PageController do
  use DocSupplyWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
