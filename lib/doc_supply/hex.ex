defmodule DocSupply.Hex do
  # TODO integrate with "has_docs" on releases
  def get_package_details(package) do
    case :hex_api_package.get(config(), package) do
      {:ok, {200, _, %{} = details}} ->
        data = %{
          package: Map.fetch!(details, "name"),
          latest_stable_version: Map.fetch!(details, "latest_stable_version"),
          versions:
            details
            |> Map.fetch!("releases")
            |> Enum.map(&Map.fetch!(&1, "version"))
            |> MapSet.new()
        }

        {:ok, data}

      _ ->
        :error
    end
  end

  defp config do
    :hex_core.default_config()
    |> Map.merge(%{
      http_user_agent_fragment: user_agent_fragment(),
      repo_url: "http://localhost:4010"
    })
  end

  def user_agent_fragment do
    [
      "(doc_supply/",
      Application.spec(:doc_supply, :vsn) |> List.to_string(),
      ") ",
      "(httpc/",
      Application.spec(:inets, :vsn) |> List.to_string(),
      ")"
    ]
    |> IO.iodata_to_binary()
  end
end
