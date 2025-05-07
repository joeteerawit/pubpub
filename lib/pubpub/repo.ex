defmodule Pubpub.Repo do
  use Ecto.Repo,
    otp_app: :pubpub,
    adapter: Ecto.Adapters.Postgres
end
