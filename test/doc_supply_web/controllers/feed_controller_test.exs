defmodule DocSupplyWeb.FeedControllerTest do
  use DocSupplyWeb.ConnCase

  setup _ do
    start_supervised!(DocSupplyWeb.Repository)
    :ok
  end

  describe "GET /feeds/:package" do
    test "renders 404 error for missing package", %{conn: conn} do
      conn = get(conn, ~p"/feeds/not_found")

      assert xml_response(conn, 404) ==
               """
               <?xml version="1.0" encoding="UTF-8"?>
               <error>
                 <code>404</code>
                 <detail>Not Found</detail>
               </error>\
               """
    end

    test "renders feed details for simple existing package", %{conn: conn} do
      conn = get(conn, ~p"/feeds/brick")

      assert xml_response(conn, 200) ==
               """
               <?xml version="1.0" encoding="UTF-8"?>
               <entry>
                 <version>0.1.0</version>
                 <url>http://localhost:4002/docsets/brick.tgz</url>
               </entry>\
               """
    end

    test "renders feed details when there are multiple versions", %{conn: conn} do
      conn = get(conn, ~p"/feeds/multi_format")

      assert xml_response(conn, 200) ==
               """
               <?xml version="1.0" encoding="UTF-8"?>
               <entry>
                 <version>0.1.2</version>
                 <url>http://localhost:4002/docsets/multi_format.tgz</url>
                 <other_versions>
                   <version>
                     <name>0.1.1</name>
                   </version>
                   <version>
                     <name>0.1.0</name>
                   </version>
                 </other_versions>
               </entry>\
               """
    end
  end
end
