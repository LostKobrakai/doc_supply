defmodule DocSupply do
  @moduledoc """
  DocSupply keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  require EEx
  alias Exqlite.Basic

  def build(package, version) do
    path = Path.join(["tmp/storage", package, version])
    target = Path.join(path, "#{package}.docset")
    feed = Path.join(path, "#{package}.tgz")
    archive = Path.join(path, "docs.tar.gz")
    index = Path.join(target, "Contents/Resources/docSet.dsidx")
    info_plist = Path.join(target, "Contents/Info.plist")
    meta_json = Path.join(target, "meta.json")
    files = Path.join(target, "/Contents/Resources/Documents")
    config = :hex_core.default_config()

    with {:ok, {200, _, body}} <-
           :hex_api_release.get(config, package, version),
         true <- body["has_docs"],
         url = Path.join(body["url"], "docs"),
         {:ok, {200, _, body}} <- :hex_http.request(config, :get, url, %{}, :undefined) do
      File.rm_rf!(target)
      File.mkdir_p!(path)
      File.write!(archive, body)
      File.mkdir_p!(files)

      extract_docs(archive, files)
      patch_css(files)
      build_info_plist(info_plist, package)
      build_meta(meta_json, package, version)
      build_index(index)
      build_toc(files)
      compress_for_feed(target, feed)
    end
  end

  defp extract_docs(archive, files) do
    :ok = :erl_tar.extract(archive, [:compressed, {:cwd, files}])
  end

  defp build_info_plist(info_plist, package) do
    File.mkdir_p!(Path.dirname(info_plist))
    File.write!(info_plist, info_plist(release: %{id: "id", name: package}))
  end

  defp build_meta(meta_json, package, version) do
    meta = %{
      extra: %{isJavaScriptEnabled: true},
      name: package,
      version: version,
      title: package
    }

    File.write!(meta_json, Jason.encode!(meta))
  end

  defp patch_css(files) do
    [file] = Path.wildcard(Path.join(files, "dist/elixir-*.css"))
    css = File.read!(file)
    css = Regex.replace(~r/(@media screen and \(max-width: ?)\d*?px\)/, css, "\\g{1}1px)")
    css = String.replace(css, ".night-mode", ".night-mode-disabled")
    File.write!(file, [css, File.read!("lib/overwrite.css")])
  end

  defp build_index(db) do
    {:ok, conn} = Basic.open(db)

    {:ok, _, _, _} =
      Basic.exec(conn, """
      CREATE TABLE searchIndex(
        id INTEGER PRIMARY KEY,
        name TEXT,
        type TEXT,
        path TEXT
        );
      """)

    index_fn = fn name, type, path ->
      sql = "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES (?1, ?2, ?3)"
      {:ok, _, _, _} = Basic.exec(conn, sql, [name, type, path])
    end

    index_fn.("Timex", "Module", "Timex.html#content")
    index_fn.("Timex.add/2", "Function", "Timex.html#add/2")

    # close connection
    Basic.close(conn)
  end

  defp build_toc(root) do
    for path <- Path.wildcard(Path.join(root, "*.html")) do
      html = File.read!(path)
      doc = Floki.parse_document!(html)

      doc =
        Floki.traverse_and_update(doc, fn
          {:pi, _, _} = declaration ->
            declaration

          {"section", attrs, children} = node ->
            case Floki.attribute(node, "id") do
              ["functions"] -> {"section", attrs, tag_functions(children)}
              _ -> node
            end

          other ->
            other
        end)

      File.write!(path, Floki.raw_html(doc))
    end
  end

  defp tag_functions(doc) do
    Floki.traverse_and_update(doc, fn
      {"div", attrs, children} = node ->
        cond do
          "functions-list" in Floki.attribute(node, "class") ->
            children =
              Enum.flat_map(children, fn
                {_node, _, _} = function ->
                  [id] = Floki.attribute(function, "id")
                  name = "//apple_ref/cpp/Function/#{URI.encode_www_form(id)}"
                  link = {"a", [{"name", name}, {"class", "dashAnchor"}], []}
                  [link, function]

                text ->
                  [text]
              end)

            {"div", attrs, children}

          true ->
            node
        end

      other ->
        other
    end)
  end

  defp compress_for_feed(target, file) do
    files =
      for path <- Path.wildcard(Path.join(target, "**/*")),
          file = Path.basename(path),
          file != ".DS_Store",
          do: String.to_charlist(path)

    :erl_tar.create(String.to_charlist(file), files, [:compressed])
  end

  info = "lib/info.plist.eex"
  @external_resource info
  EEx.function_from_file(:def, :info_plist, info, [:assigns])
end
