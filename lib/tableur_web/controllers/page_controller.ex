defmodule TableurWeb.PageController do
  use TableurWeb, :controller

  def home(conn, _params) do
    render(conn, :home, active_tab: :home)
  end
end
