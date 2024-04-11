defmodule DocSupplyWeb.Repository do
  defmodule Router do
    use Plug.Builder

    # plug :inspect
    plug Plug.Static,
      at: "/",
      from: "test/fixtures/hex/public"

    plug :error

    def inspect(conn, _), do: IO.inspect(conn)
    def error(conn, _), do: Plug.Conn.send_resp(conn, 404, "Not found")
  end

  def child_spec(_) do
    Bandit.child_spec(ip: {127, 0, 0, 1}, port: 4010, plug: Router)
  end

  def init(config) do
    config =
      Map.merge(config, %{
        api_url: "http://localhost:4010/api",
        repo_url: "http://localhost:4010",
        repo_name: "doc_supply"
      })

    {:ok, {200, _, public_key}} = :hex_repo.get_public_key(config)

    Map.merge(config, %{repo_public_key: public_key})
  end
end
