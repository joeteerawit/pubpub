defmodule Pubpub.Packages do
  require Logger

  alias Pubpub.Packages.Signature

  @package_dir "priv/packages"
  @upload_dir "priv/packages/uploads"
  @expiration_minutes 10

  @spec get_version_metadata(String.t(), String.t()) :: {:ok, map()} | {:error, :not_found}
  defdelegate get_version_metadata(package_name, version),
    to: Pubpub.Packages.GetVersionMetadata,
    as: :perform

  @spec get_all_versions(String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_all_versions(package_name) do
    "#{@package_dir}/#{package_name}"
    |> File.ls()
    |> case do
      {:ok, versions} ->
        {:ok, %{"name" => package_name, "versions" => versions, "latest" => List.last(versions)}}

      {:error, :enoent} ->
        {:error, :not_found}
    end
  end

  @spec get_archive_path(String.t(), String.t()) :: {:ok, String.t()} | {:error, :not_found}
  def get_archive_path(package_name, version) do
    path = "#{@package_dir}/#{package_name}/#{version}/#{package_name}-#{version}.tar.gz"

    if File.exists?(path) do
      {:ok, path}
    else
      {:error, :not_found}
    end
  end

  @spec gen_pre_signed_url() :: {:ok, map()} | {:error, String.t()}
  def gen_pre_signed_url() do
    # key = "uploads/#{package_name}-#{version}.tar.gz"
    now = DateTime.utc_now()
    expires_at = now |> DateTime.add(@expiration_minutes * 60, :second)
    iso_expiry = DateTime.to_iso8601(expires_at)
    upload_url = Path.join(PubpubWeb.Endpoint.url(), "/api/upload")

    policy = %{
      # "key" => key,
      "expires" => iso_expiry,
      "max_size" => 10 * 1024 * 1024
    }

    with {:ok, encoded_policy} <- Jason.encode(policy),
         {:ok, signature} <- Signature.sign(encoded_policy) do
      {:ok,
       %{
         url: upload_url,
         fields: %{
           #  "key" => key,
           "package_name" => "kyc",
           "version" => "v1.1.0",
           "timestamp" => now |> DateTime.to_iso8601(),
           "policy" => Base.encode64(encoded_policy),
           "x-pub-signature" => signature,
           "x-pub-expires" => iso_expiry
         }
       }}
    else
      reason ->
        Logger.error("Failed to generate pre-signed upload URL: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @spec upload(map()) :: {:ok, :upload_completed} | {:error, any()}
  def upload(%{"file" => upload, "package_name" => package_name, "version" => version}) do
    upload_dir = "#{@upload_dir}/#{package_name}/#{version}"
    upload_file = Path.join(upload_dir, "#{package_name}-#{version}.tar.gz")

    with :ok <- File.mkdir_p(upload_dir),
         {:ok, _} <- File.copy(upload.path, upload_file) do
      {:ok, :upload_completed}
    else
      reason ->
        Logger.error("Failed to upload package: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def upload(_), do: {:error, :invalid_params}

  @spec finalize_upload(String.t(), String.t()) ::
          {:ok, :process_completed} | {:error, :process_failed}
  def finalize_upload(package_name, version) do
    pakcage_dir = Path.join(@package_dir, "/#{package_name}/#{version}")
    delete_dir = Path.join(@upload_dir, "/#{package_name}")

    src_path =
      Path.join(@upload_dir, "/#{package_name}/#{version}/#{package_name}-#{version}.tar.gz")

    dest_path = Path.join(pakcage_dir, "#{package_name}-#{version}.tar.gz")

    with :ok <- File.mkdir_p(pakcage_dir),
         :ok <- File.rename(src_path, dest_path),
         {:ok, _} <- File.rm_rf(delete_dir) do
      {:ok, :process_completed}
    else
      reason ->
        Logger.error("Failed to finalize upload: #{inspect(reason)}")
        {:error, :process_failed}
    end
  end
end
