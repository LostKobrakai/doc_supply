defmodule DocSupplyWeb.Repository do
  defmodule Router do
    use Plug.Builder

    # plug :inspect
    plug Plug.Static,
      at: "/",
      from: "test/fixtures/hex/public"

    def inspect(conn, _), do: IO.inspect(conn)
  end

  def child_spec(_) do
    Bandit.child_spec(port: 4010, plug: Router)
  end
end
