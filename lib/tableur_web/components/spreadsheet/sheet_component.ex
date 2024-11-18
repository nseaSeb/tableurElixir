# lib/my_app_web/live/components/spreadsheet_component.ex
defmodule TableurWeb.SheetComponent do
  use TableurWeb, :live_component
  require Logger

  def mount(socket) do
    {:ok,
     socket
     |> assign(uploaded_file: nil, file_content: nil, active_row_dropdown: nil)

     |> allow_upload(:file,
       accept: ~w(.txt .csv .xls .xlsx),
       max_entries: 1,
       max_file_size: 10_000_000
     )}
  end

  def update(assigns, socket) do
    Logger.info("update called in SheetComponent")
    Logger.info("Received data: #{inspect(assigns[:data])}")

    {:ok,
     socket
     # Assurez-vous que 'data' est passé et assigné correctement
     |> assign(assigns)
     # Initialiser 'data' à une liste vide si rien n'est passé

     |> assign(:edit_row, false)}
  end

  def handle_event("add_row", _params, socket) do
    data = socket.assigns.data
    # Trouver le nombre de cellules dans la première ligne (ou dans toute ligne)
    num_cells = length(List.first(data))

    # Créer une nouvelle ligne avec le même nombre de cellules
    new_line = List.duplicate("", num_cells)

    # Ajouter la nouvelle ligne à la fin
    updated_data = data ++ [new_line]

    {:noreply,
     socket
     |> assign(data: updated_data)}
  end

  def handle_event("add_col", _params, socket) do
    data = socket.assigns.data

    # Ajouter une colonne à chaque ligne
    updated_data =
      Enum.map(data, fn row ->
        # Ajouter une cellule à la fin de la ligne
        row ++ [""]
      end)

    # Mettre à jour les données dans l'assign
    {:noreply, socket |> assign(data: updated_data)}
  end

  def handle_event("delete_col", %{"value" => col}, socket) do
    data = socket.assigns.data
    col_index = String.to_integer(col) - 1

    # Supprimer la colonne spécifiée pour chaque ligne
    updated_data =
      Enum.map(data, fn row ->
        List.delete_at(row, col_index)
      end)

    # Mettre à jour les données dans l'assign
    {:noreply, socket |> assign(data: updated_data)}
  end

  # def handle_event("delete_row", params, socket) do
  #   Logger.info("delete_row")
  #   IO.inspect(params)
  #   {:noreply, socket}
  # end
  @impl true
  def handle_event("row_menu_click", %{"row" => row}, socket) do
    Logger.warning("row menu click")
    {:noreply, assign(socket, :active_row_dropdown, String.to_integer(row))}
  end
  @impl true
  def handle_event("delete_row", %{"row" => index}, socket) do
    index = String.to_integer(index)
    new_data = List.delete_at(socket.assigns.data, index)

    {:noreply, assign(socket, :data, new_data)}
  end

  @impl true
  def handle_event("insert_row_after", %{"row" => index}, socket) do
    index = String.to_integer(index)

    # La donnée actuelle (la ligne à insérer)
    current_row = Enum.at(socket.assigns.data, index)

    # Nouvelle ligne, tu peux personnaliser la valeur ici
    new_row = List.duplicate(nil, length(current_row))

    # Insertion de la nouvelle ligne après l'index donné
    updated_data =
      socket.assigns.data
      |> List.insert_at(index + 1, new_row)

    {:noreply, assign(socket, :data, updated_data)}
  end

  @impl true
  def handle_event("insert_row_before", %{"row" => index}, socket) do
    index = String.to_integer(index)

    # La donnée actuelle (la ligne pour définir la structure)
    current_row = Enum.at(socket.assigns.data, index)

    # Nouvelle ligne (vide ou avec des valeurs personnalisées)
    new_row = List.duplicate(nil, length(current_row))

    # Insertion de la nouvelle ligne à l'index actuel
    updated_data =
      socket.assigns.data
      |> List.insert_at(index, new_row)

    {:noreply, assign(socket, :data, updated_data)}
  end

  @impl true
  def handle_event("duplicate_row", %{"row" => index}, socket) do
    index = String.to_integer(index)
    # Récupérer la ligne à dupliquer
    row_to_duplicate = Enum.at(socket.assigns.data, index)
    # Insérer une copie de la ligne après la ligne existante
    updated_data =
      socket.assigns.data
      |> List.insert_at(index + 1, row_to_duplicate)

    {:noreply, assign(socket, :data, updated_data)}
  end

  def handle_event("edit_cell", %{"col" => col, "row" => row}, socket) do
    Logger.warning("edit col: #{col} / row: #{row}")

    {:noreply,
     assign(socket,
       edit_row: true,
       row: row,
       col: col
     )}
  end

  def handle_event("close_modal", %{}, socket) do
    Logger.warning("close_modal")

    {:noreply,
     assign(socket,
       edit_row: false,
       row: 0,
       col: 0
     )}
  end

  defp number_to_letter(number) do
    cond do
      number <= 0 -> ""
      true -> number_to_letter(div(number - 1, 26)) <> <<rem(number - 1, 26) + ?A>>
    end
  end

  # Ajoutez d'autres fonctions pour gérer l'édition des cellules,
  # le calcul des formules, etc.
  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
