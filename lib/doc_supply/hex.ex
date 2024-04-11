defmodule DocSupply.Hex do
  def get_package_details(package) do
    case :hex_repo.get_package(config(), package) do
      {:ok, {200, _, %{} = details}} ->
        versions =
          details.releases
          |> Stream.map(& &1.version)
          |> MapSet.new()

        latest_stable =
          versions
          |> Enum.sort({:desc, Version})
          |> Enum.find_value(fn version ->
            case Version.parse!(version) do
              %{pre: []} -> version
              _ -> nil
            end
          end)

        data = %{
          package: details.name,
          latest_stable_version: latest_stable,
          versions: versions
        }

        {:ok, data}

      _ ->
        {:error, :not_found}
    end
  end

  def fetch_docset(package, version) do
    config = config()

    with {:ok, {200, _, body}} <- :hex_repo.get_docs(config, package, version),
         {:ok, docset} <- find_docset(body) do
      {:ok, docset}
    else
      _ -> {:error, :not_found}
    end
  end

  defp find_docset(compressed_docs) do
    with {:ok, files} <- extract_docs(compressed_docs),
         docset_folder when not is_nil(docset_folder) <-
           Enum.find_value(files, fn {path, _} ->
             if path =~ ".docset/", do: path |> Path.split() |> List.first()
           end) do
      docset_files =
        Enum.filter(files, fn {path, _} ->
          String.starts_with?(path, docset_folder) and !String.ends_with?(path, ".DS_Store")
        end)

      {:ok, docset_files}
    else
      _ -> :error
    end
  end

  def compress_docset(package, docset_files) do
    root = Path.join(System.tmp_dir!(), package)
    docset_path = Path.join(root, "#{package}.docset")
    tar_path = Path.join(root, "#{package}.tgz")

    Enum.map(docset_files, fn {path, bin} ->
      [_ | rest] = Path.split(path)
      p = Path.join([docset_path | rest])
      File.mkdir_p!(Path.dirname(p))
      File.write!(p, bin)
    end)

    # :ok =
    #   :erl_tar.create(
    #     String.to_charlist(tar_path),
    #     [{~c"#{package}.docset", ~c"#{docset_path}"}],
    #     [:compressed]
    #   )

    {_, 0} =
      System.cmd("tar", ["-czf", tar_path, "#{package}.docset"], cd: Path.dirname(tar_path))

    try do
      tar_path |> File.read!()
    after
      File.rm_rf!(root)
    end
  end

  defp extract_docs(compressed_docs) do
    with {:ok, files} <- :erl_tar.extract({:binary, compressed_docs}, [:compressed, :memory]) do
      {:ok, for({path, contents} <- files, do: {List.to_string(path), contents})}
    end
  end

  defp config do
    config =
      :hex_core.default_config()
      |> Map.merge(%{
        http_adapter: {DocSupply.HexCore.FinchHTTP, %{name: DocSupply.Finch}},
        http_user_agent_fragment: user_agent_fragment()
      })

    if provider =
         :doc_supply
         |> Application.get_env(__MODULE__, [])
         |> Keyword.get(:config_provider) do
      provider.init(config)
    else
      config
    end
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
