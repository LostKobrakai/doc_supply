defmodule DocSupplyWeb.FeedController do
  use DocSupplyWeb, :controller

  def show(conn, %{"package" => package}) do
    package = Path.basename(package, ".xml")

    case DocSupply.Hex.get_package_details(package) do
      {:ok, details} ->
        render(conn, :show, details)

      _ ->
        conn
        |> put_status(:not_found)
        |> put_view(DocSupplyWeb.ErrorXML)
        |> render(:"404")
    end
  end
end
