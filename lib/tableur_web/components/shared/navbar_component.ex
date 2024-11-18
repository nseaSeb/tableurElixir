defmodule TableurWeb.NavbarComponent do
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

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("browse", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", _params, socket) do
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
        TableurWeb.Endpoint.broadcast("spreadsheet:updates", "file_uploaded", %{content: content})

        {:noreply,
         socket
         |> assign(:file_content, content)
         |> put_flash(:info, "Fichier traité avec succès")}

      [error] ->
        # Debug log
        Logger.error("Error processing content: #{inspect(error)}")

        {:noreply,
         socket
         |> put_flash(:error, "Erreur lors du traitement : #{inspect(error)}")}

      [] ->
        {:noreply,
         socket
         |> put_flash(:error, "Aucun fichier traité")}
    end
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
