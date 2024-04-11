defmodule DocSupplyWeb.DocSetControllerTest do
  use DocSupplyWeb.ConnCase

  setup _ do
    start_supervised!(DocSupplyWeb.Repository)
    :ok
  end

  describe "GET /docsets/:package" do
    test "renders 404 error for missing package", %{conn: conn} do
      conn = get(conn, ~p"/docsets/not_found")

      assert xml_response(conn, 404) ==
               """
               <?xml version="1.0" encoding="UTF-8"?>
               <error>
                 <code>404</code>
                 <detail>Not Found</detail>
               </error>\
               """
    end

    test "redirects to versioned endpoint for existing packets", %{conn: conn} do
      conn = get(conn, ~p"/docsets/brick")

      assert redirected_to(conn, 302) == ~p"/docsets/versions/brick/0.1.0/brick.tgz"
    end
  end

  describe "GET /docsets/versions/:package/:version/:file" do
    test "renders 404 error for missing package", %{conn: conn} do
      conn = get(conn, ~p"/docsets/versions/not_found/0.1.0/not_found.tgz")

      assert xml_response(conn, 404) ==
               """
               <?xml version="1.0" encoding="UTF-8"?>
               <error>
                 <code>404</code>
                 <detail>Not Found</detail>
               </error>\
               """
    end

    test "renders 404 error for invalid version", %{conn: conn} do
      conn = get(conn, ~p"/docsets/versions/brick/1.0.0/brick.tgz")

      assert xml_response(conn, 404) ==
               """
               <?xml version="1.0" encoding="UTF-8"?>
               <error>
                 <code>404</code>
                 <detail>Not Found</detail>
               </error>\
               """
    end

    test "renders 404 error for packet without docset in docs", %{conn: conn} do
      conn = get(conn, ~p"/docsets/versions/brick/0.1.0/brick.tgz")

      assert xml_response(conn, 404) ==
               """
               <?xml version="1.0" encoding="UTF-8"?>
               <error>
                 <code>404</code>
                 <detail>Not Found</detail>
               </error>\
               """
    end

    test "sends docset for existing package", %{conn: conn} do
      conn = get(conn, ~p"/docsets/versions/ex_doc_docset/0.1.1/ex_doc_docset.tgz")

      assert result = response(conn, 200)

      expected = File.read!("test/fixtures/ex_doc_docset.tgz")

      {:ok, result_files} = :erl_tar.extract({:binary, result}, [:compressed, :memory])
      {:ok, expected_files} = :erl_tar.extract({:binary, expected}, [:compressed, :memory])

      # result_files = Map.new(result_files, fn {p, b} -> {List.to_string(p), b} end)
      # expected_files = Map.new(expected_files, fn {p, b} -> {List.to_string(p), b} end)

      # assert Map.keys(result_files) == Map.keys(expected_files)

      # Enum.all?(Map.keys(result_files), fn k ->
      #   assert result_files[k] == expected_files[k]
      # end)

      assert length(expected_files) == length(result_files)
      assert Enum.sort(expected_files) == Enum.sort(result_files)
    end
  end
end
