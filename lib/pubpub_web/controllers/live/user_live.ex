defmodule PubpubWeb.Live.UserLive do
  use PubpubWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
