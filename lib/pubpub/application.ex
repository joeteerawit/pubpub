defmodule Pubpub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    File.mkdir_p!("priv/packages")
    File.mkdir_p!("priv/static/packages")
    File.mkdir_p!("priv/static/uploads/tmp")

    children = [
      PubpubWeb.Telemetry,
      Pubpub.Repo,
      {DNSCluster, query: Application.get_env(:pubpub, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Pubpub.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Pubpub.Finch},
      # Start a worker by calling: Pubpub.Worker.start_link(arg)
      # {Pubpub.Worker, arg},
      # Start to serve requests, typically the last entry
      PubpubWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pubpub.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PubpubWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
