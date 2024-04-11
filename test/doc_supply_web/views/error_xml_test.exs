defmodule DocSupplyWeb.ErrorXMLTest do
  use DocSupplyWeb.ConnCase, async: true

  test "renders 404" do
    assert DocSupplyWeb.ErrorXML.render("404.xml", %{}) == [
             :xml_decl,
             {:error, [],
              [
                {:code, [], "404"},
                {:detail, [], "Not Found"}
              ]}
           ]
  end

  test "renders 500" do
    assert DocSupplyWeb.ErrorXML.render("500.xml", %{}) == [
             :xml_decl,
             {:error, [],
              [
                {:code, [], "500"},
                {:detail, [], "Internal Server Error"}
              ]}
           ]
  end
end
