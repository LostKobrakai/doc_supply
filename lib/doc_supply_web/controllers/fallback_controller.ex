defmodule DocSupplyWeb.FallbackController do
  use Phoenix.Controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(DocSupplyWeb.ErrorXML)
    |> render(:"404")
  end
end
