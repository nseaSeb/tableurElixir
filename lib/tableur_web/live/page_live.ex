defmodule TableurWeb.PageLive.Index do
  use TableurWeb, :live_view
  require Logger
  @impl true
  def mount(_params, _session, socket) do
    Logger.warning("PageLive mount")

    {:ok,
     assign(socket,
       pagination_page: 1,
       total_pages: 0,
       active_tab: :live,
       has_header: true,
       data: []
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    Logger.info("PageLive handle_param")
    Logger.warning(socket.assigns.live_action)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end
  defp apply_action(socket, :index,_params) do
    socket
    |> assign(:page_title, "Tableur")
    |> assign(:apply_action, :index)
  end
  defp apply_action(socket, :modal,_params) do
    socket
    |> assign(:page_title, "Tableur")
    |> assign(:apply_action, :modal)
  end
  defp apply_action(socket, _nil,_params) do
    socket
    |> assign(:page_title, "Tableur")
    |> assign(:apply_action, :index)
  end
  @impl true
  def handle_info(%{event: "file_uploaded", payload: %{content: content}}, socket) do
    Logger.info("Message PubSub reçu avec succès")

    # Mettre à jour les données du tableau
    updated_data = content
    IO.inspect(updated_data)
    {:noreply, assign(socket, data: updated_data)}
  end


  def handle_event("has_entete_change", %{"header" => header}, socket) do
    Logger.info("has_entete_change")
    Logger.warning(header)

    case header do
      "false" ->
        {:noreply, assign(socket, has_header: false)}

      _ ->
        {:noreply, assign(socket, has_header: true)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="overflow-none">
      <.live_component module={TableurWeb.NavbarComponent} id="main_navbar" />

      <.live_component
        module={TableurWeb.SpreadsheetComponent}
        id="spreadsheet"
        live_action={@live_action}
        has_header={@has_header}
      />
    </div>
    """
  end
end
