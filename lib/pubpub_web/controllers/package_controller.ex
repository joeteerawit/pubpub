defmodule PubpubWeb.PackageController do
  use PubpubWeb, :controller

  require IEx

  alias Pubpub.Packages.GetArchivePath
  alias Pubpub.Packages.GetVersionMetadata
  alias Pubpub.Packages.ListAllVersion

  @spec list_versions(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def list_versions(conn, %{"package" => package_name} = params) do
    case ListAllVersion.perform(package_name) do
      {:ok, package} ->
        conn
        |> put_req_header("Content-Type", "application/vnd.pub.v2+json")
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
    case GetVersionMetadata.perform(package_name, version) do
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
    case GetArchivePath.perform(package_name, version) do
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
  """
  def upload(conn, params) do
    # Log the received params for debugging
    IO.inspect(params, label: "Upload Params")

    # Extract package information
    package_name = Map.get(params, "package_name", "unknown_package")
    version = Map.get(params, "version", "unknown_version")

    # Check if we have a file upload
    case conn.body_params do
      %{"file" => upload} when is_map(upload) ->
        # Create temp directory if it doesn't exist
        upload_dir = "priv/static/uploads/tmp/#{package_name}/#{version}"
        File.mkdir_p!(upload_dir)

        # Copy the file to the temp directory
        dest_path = Path.join(upload_dir, "#{package_name}-#{version}.tar.gz")
        File.copy!(upload.path, dest_path)

        IO.puts("File saved to: #{dest_path}")

        # Send proper response
        conn
        |> put_status(:no_content)
        |> put_req_header("Content-Type", "application/vnd.pub.v2+json")
        |> put_resp_header(
          "location",
          "#{PubpubWeb.Endpoint.url()}/api/finalize?package=#{package_name}&version=#{version}"
        )
        |> send_resp(204, "")

      _ ->
        # No file found in the upload
        conn
        |> put_status(:bad_request)
        |> put_req_header("Content-Type", "application/vnd.pub.v2+json")
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
    IO.inspect(params, label: "finalize upload: ")
    # Create the destination directory
    dest_dir = "priv/static/packages/#{package_name}/#{version}"
    File.mkdir_p!(dest_dir)

    # Source and destination paths
    src_path =
      "priv/static/uploads/tmp/#{package_name}/#{version}/#{package_name}-#{version}.tar.gz"

    dest_path = "#{dest_dir}/#{package_name}-#{version}.tar.gz"

    # Check if the source file exists
    if File.exists?(src_path) do
      # Move the file
      File.rename!(src_path, dest_path)

      # Optionally clean up the temp directory
      File.rm_rf!("priv/static/uploads/tmp/#{package_name}/#{version}")

      IO.puts("Package finalized: #{dest_path}")

      # Return success response
      conn
      |> put_req_header("Content-Type", "application/vnd.pub.v2+json")
      |> json(%{
        "success" => %{
          "message" => "Package #{package_name} version #{version} published successfully"
        }
      })
    else
      # File not found
      conn
      |> put_status(:not_found)
      |> put_req_header("Content-Type", "application/vnd.pub.v2+json")
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
