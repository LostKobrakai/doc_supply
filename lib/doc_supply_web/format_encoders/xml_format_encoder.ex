defmodule DocSupplyWeb.XmlFormatEncoder do
  def encode_to_iodata!(data) do
    XmlBuilder.generate_iodata(data)
  end
end
