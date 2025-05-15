defmodule PubpubWeb.PackageController do
  use PubpubWeb, :controller

  require Logger

  alias Pubpub.Packages

  @spec list_versions(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def list_versions(conn, %{"package" => package_name}) do
    case Packages.get_all_versions(package_name) do
      {:ok, package} ->
        conn
        |> put_flutter_headers()
        |> json(package)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: %{code: "not_found", message: "Package #{package_name} not found"}})
    end
  end

  @spec publishing(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def publishing(conn, _params) do
    upload_url = "#{PubpubWeb.Endpoint.url()}/api/upload"

    conn
    |> put_flutter_headers()
    |> json(%{
      "url" => upload_url,
      "fields" => %{
        "package_name" => "test_package",
        "version" => "0.0.1",
        "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601()
      }
    })
  end

  @spec list_security_advisories(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def list_security_advisories(conn, %{"package" => _package_name}) do
    conn
    |> put_flutter_headers()
    |> json(%{
      "advisories" => [],
      "advisoriesUpdated" => DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  @spec show_version(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show_version(conn, %{"package" => package_name, "version" => version}) do
    case Packages.get_version_metadata(package_name, version) do
      {:ok, metadata} ->
        conn
        |> put_flutter_headers()
        |> json(metadata)

      {:error, :not_found} ->
        conn
        |> put_flutter_headers()
        |> put_status(:not_found)
        |> json(%{
          error: %{
            code: "not_found",
            message: "Package #{package_name} version #{version} not found"
          }
        })
    end
  end

  @spec download(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def download(conn, %{"package" => package_name, "version" => version}) do
    case Packages.get_archive_path(package_name, version) do
      {:ok, path} ->
        send_file(conn, 200, path)

      {:error, :not_found} ->
        conn
        |> put_flutter_headers()
        |> put_status(:not_found)
        |> json(%{
          error: %{
            code: "not_found",
            message: "Package archive for #{package_name} version #{version} not found"
          }
        })
    end
  end

  @doc """
  Handles file uploads for package publishing.
  This endpoint receives the multipart form data with the package archive.
  %{
    "file" => %Plug.Upload{
      path: "/var/folders/n1/qq5t25mn711bk8g9dzym8jgh0000gn/T/plug-1747-8gPS/multipart-1747235273-778385280545-4",
      content_type: "application/octet-stream",
      filename: "package.tar.gz"
    },
    "package_name" => "test_package",
    "timestamp" => "2025-05-14T15:07:53.913632Z",
    "version" => "0.0.1"
  }
  """
  def upload(conn, %{"package_name" => package_name, "version" => version} = params) do
    case Packages.upload(params) do
      {:ok, _} ->
        conn
        |> put_status(:no_content)
        |> put_flutter_headers()
        |> put_resp_header(
          "location",
          "#{PubpubWeb.Endpoint.url()}/api/finalize?package=#{package_name}&version=#{version}"
        )
        |> send_resp(204, "")

      {:error, _} ->
        conn
        |> put_flutter_headers()
        |> put_status(:bad_request)
        |> json(%{
          "error" => %{
            "code" => "no_file",
            "message" => "No file was uploaded or file parameter is missing"
          }
        })
    end
  end

  @doc """
  Finalizes a package upload by moving the package from temp storage to permanent storage.
  """
  def finalize(conn, %{"package" => package_name, "version" => version} = params) do
    Logger.info("Finalizing upload: #{inspect(params)}")

    case Packages.finalize_upload(package_name, version) do
      {:ok, _} ->
        conn
        |> put_flutter_headers()
        |> json(%{
          "success" => %{
            "message" => "Package #{package_name} version #{version} published successfully"
          }
        })

      {:error, _} ->
        conn
        |> put_flutter_headers()
        |> put_status(:not_found)
        |> json(%{
          "error" => %{
            "code" => "file_not_found",
            "message" => "Package file not found in temporary storage"
          }
        })
    end
  end

  defp put_flutter_headers(conn) do
    conn
    |> put_req_header("Content-Type", "application/vnd.pub.v2+json")
  end
end
