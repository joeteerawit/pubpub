defmodule PubpubWeb.Live.LoginLive do
  use PubpubWeb, :login_live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
