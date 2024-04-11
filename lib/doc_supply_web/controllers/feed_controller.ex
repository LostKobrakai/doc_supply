defmodule DocSupplyWeb.FeedController do
  use DocSupplyWeb, :controller

  action_fallback DocSupplyWeb.FallbackController

  def show(conn, %{"package" => package}) do
    package = Path.basename(package, ".xml")

    with {:ok, details} <- DocSupply.Hex.get_package_details(package) do
      render(conn, :show, details)
    end
  end
end
