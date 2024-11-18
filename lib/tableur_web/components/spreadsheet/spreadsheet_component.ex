defmodule TableurWeb.SpreadsheetComponent do
  use TableurWeb, :live_component
  require Logger

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(uploaded_file: nil, file_content: nil)
     |> allow_upload(:file,
       accept: ~w(.txt .csv .xls .xlsx),
       max_entries: 1,
       max_file_size: 10_000_000
     )}
  end

  # Fonction `update` pour initialiser les données du composant
  def update(assigns, socket) do
    Logger.info("update called in SpreadsheetComponent")
    # Vérifier si les données sont présentes
    Logger.info("file_content: #{inspect(assigns[:file_content])}")

    # Si `file_content` est nil ou vide, initialiser une table vide
    file_content = assigns[:file_content] || []

    # Créer des tabs et sheets conditionnels
    tabs = if file_content == [], do: [%{id: 0, name: "Sheet0"}], else: [%{id: 0, name: "Sheet1"}]
    sheets = if file_content == [], do: %{0 => init_sheet()}, else: %{0 => file_content}

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:file_content, file_content)
     |> assign(:tabs, tabs)
     |> assign(:active_tab, 0)
     |> assign(:sheets, sheets)}
  end
  # Fonction de gestion des événements
  @impl true
  def handle_info({:file_content_updated, content}, socket) do
    Logger.info("handle_info received")

    # Assurez-vous que les données sont bien mises à jour
    updated_sheets =
      Map.update(socket.assigns.sheets, socket.assigns.active_tab, fn _sheet -> content end)

    {:noreply, assign(socket, sheets: updated_sheets, file_content: content)}
  end
  @impl true
  def handle_event("close_modal", _, socket) do

    # Go back to the :index live action
    {:noreply, push_patch(socket, to: "/")}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    Logger.warning("validate")
    {:noreply, socket}
  end

  @impl true
  def handle_event("upload", _params, socket) do

    Logger.info("Processing upload")

    case consume_uploaded_entries(socket, :file, fn %{path: path}, entry ->
           # Logger.info("Processing file: #{entry.client_name}, type: #{entry.client_type}")
           result = handle_uploaded_file(path, entry.client_type)
           result
         end) do
      [content] when is_binary(content) or is_list(content) ->
        # Debug log
        Logger.info("Content processed successfully")


        {:noreply,
         socket
         |> assign(:file_content, content)
         |> put_flash(:info, "Fichier traité avec succès")
         |> assign(:live_action, :index)
         }

      [error] ->
        # Debug log
        Logger.error("Error processing content: #{inspect(error)}")

        {:noreply,
         socket
         |> put_flash(:error, "Erreur lors du traitement : #{inspect(error)}")
         |> push_patch(to: ~p"/")}

      [] ->
        {:noreply,
         socket
         |> put_flash(:error, "Aucun fichier traité")
         |> push_patch(to: ~p"/")}
    end
  end
  defp init_sheet do
    for _ <- 1..4, do: for(_ <- 1..4, do: "")
  end
  defp handle_uploaded_file(path, content_type) do
    case content_type do
      "text/plain" ->
        Logger.warning("upload TXT")
        {:ok, content} = process_txt(path)
        {:ok, content}

      "text/csv" ->
        Logger.warning("upload CSV")
        {:ok, content} = process_csv(path)
        {:ok, content}

      "application/vnd.ms-excel" ->
        Logger.warning("upload Excel")
        {:ok, content} = process_xls(path)
        {:ok, content}

      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" ->
        Logger.warning("upload XML")
        {:ok, content} = process_xlsx(path)
        {:ok, content}

      _ ->
        Logger.warning("upload error")
        {:error, "Type de fichier non supporté: #{content_type}"}
    end
  end

  defp process_txt(path) do
    case File.read(path) do
      {:ok, content} -> {:ok, content}
      {:error, reason} -> {:error, reason}
    end
  end

  defp process_csv(path) do
    try do
      content =
        path
        |> File.stream!()
        |> CSV.decode(separator: ?;)
        |> Enum.map(fn {:ok, row} ->
          # Chaque ligne est déjà une liste de valeurs
          row
        end)
        |> Enum.to_list()

      {:ok, content}
    rescue
      e -> {:error, "Erreur lors du traitement CSV: #{Exception.message(e)}"}
    end
  end

  defp process_xls(path) do
    case Xlsxir.multi_extract(path, 0) do
      {:ok, table_id} ->
        content = Xlsxir.get_list(table_id)
        Xlsxir.close(table_id)
        {:ok, content}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp process_xlsx(path) do
    process_xls(path)
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"


end
