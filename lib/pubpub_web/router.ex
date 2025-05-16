defmodule PubpubWeb.Router do
  use PubpubWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PubpubWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PubpubWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/api", PubpubWeb do
    pipe_through :api

    # List all versions of a package
    # https://github.com/dart-lang/pub/blob/master/doc/repository-spec-v2.md#list-security-advisories-for-a-package
    get "/packages/:package", PackageController, :list_versions

    # Publishing Packages
    # https://github.com/dart-lang/pub/blob/master/doc/repository-spec-v2.md#list-security-advisories-for-a-package
    get "/packages/versions/new", PackageController, :pre_sign_upload

    # List security advisories for a package
    # https://github.com/dart-lang/pub/blob/master/doc/repository-spec-v2.md#list-security-advisories-for-a-package
    get "/packages/:package/advisories", PackageController, :list_security_advisories

    # (Deprecated) Inspect a specific version of a package
    # Deprecated as of Dart 2.8
    # https://github.com/dart-lang/pub/blob/master/doc/repository-spec-v2.md#deprecated-inspect-a-specific-version-of-a-package
    get "/packages/:package/versions/:version", PackageController, :show_version

    # Handle uploads - NOTE: Changed to POST method
    post "/upload", PackageController, :upload
    get "/finalize", PackageController, :finalize
  end

  scope "/packages", PubpubWeb do
    # (Deprecated) Download a specific version of a package
    # Deprecated as of Dart 2.8
    # https://github.com/dart-lang/pub/blob/master/doc/repository-spec-v2.md#deprecated-download-a-specific-version-of-a-package
    get "/packages/:package/versions/:version", PackageController, :download
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:pubpub, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PubpubWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
