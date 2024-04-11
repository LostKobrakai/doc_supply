defmodule DocSupplyWeb.DocSetController do
  use DocSupplyWeb, :controller

  action_fallback DocSupplyWeb.FallbackController

  def show(conn, %{"package" => package, "version" => version, "file" => _}) do
    package = Path.basename(package, ".xml")

    with {:ok, docset_files} <- DocSupply.Hex.fetch_docset(package, version) do
      tar = DocSupply.Hex.compress_docset(package, docset_files)

      conn
      |> put_resp_content_type("application/x-tar+gzip", nil)
      |> send_resp(200, tar)
    end
  end

  def show(conn, %{"package" => package}) do
    package = Path.basename(package, ".tgz")

    with {:ok, details} <- DocSupply.Hex.get_package_details(package) do
      target =
        ~p"/docsets/versions/#{details.package}/#{details.latest_stable_version}/#{details.package <> ".tgz"}"

      redirect(conn, to: target)
    end
  end
end
