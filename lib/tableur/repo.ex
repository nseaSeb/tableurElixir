defmodule Tableur.Repo do
  use Ecto.Repo,
    otp_app: :tableur,
    adapter: Ecto.Adapters.Postgres
end
