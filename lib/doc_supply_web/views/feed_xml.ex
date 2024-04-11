defmodule DocSupplyWeb.FeedXML do
  use DocSupplyWeb, :verified_routes
  import XmlBuilder

  def show(assigns) do
    document(:entry, [], [
      element(:version, [], assigns.latest_stable_version),
      element(:url, [], url(~p"/docsets/#{assigns.package <> ".tgz"}"))
      | maybe_other_versions(assigns.versions, assigns.latest_stable_version)
    ])
  end

  defp maybe_other_versions(versions, latest_stable_version) do
    other_versions = MapSet.delete(versions, latest_stable_version)
    other_versions_sorted_list = Enum.sort(other_versions, {:desc, Version})

    with [_ | _] = list <- other_versions_sorted_list do
      [
        element(
          :"other-versions",
          [],
          Enum.map(list, &element(:version, [], [element(:name, [], &1)]))
        )
      ]
    end
  end
end
