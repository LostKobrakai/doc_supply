defmodule DocSupply.HexCore.FinchHTTP do
  @behaviour :hex_http

  @impl true
  def request(method, uri, headers, body, adapter_config) do
    name = Map.fetch!(adapter_config, :name)

    body =
      case body do
        {_, body} -> body
        :undefined -> nil
      end

    request = Finch.build(method, uri, Map.to_list(headers), body)

    with {:ok, response} <- Finch.request(request, name) do
      {:ok, {response.status, Map.new(response.headers), response.body}}
    end
  end
end
