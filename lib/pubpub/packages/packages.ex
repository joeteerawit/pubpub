defmodule Pubpub.Packages do
  require Logger

  @package_dir "priv/packages"
  @upload_dir "priv/packages/uploads"

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

  @spec upload(map()) :: {:ok, :upload_completed} | {:error, :upload_failed}
  def upload(%{"file" => upload, "package_name" => package_name, "version" => version}) do
    upload_dir = "#{@upload_dir}/#{package_name}/#{version}"
    upload_file = Path.join(upload_dir, "#{package_name}-#{version}.tar.gz")

    with :ok <- File.mkdir(upload_dir),
         {:ok, _} <- File.copy(upload.path, upload_file) do
      {:ok, :upload_completed}
    else
      reason ->
        Logger.error("Failed to upload package: #{inspect(reason)}")
        {:error, :upload_failed}
    end
  end

  def upload(_), do: {:error, :invalid_params}

  @spec finalize_upload(String.t(), String.t()) ::
          {:ok, :process_completed} | {:error, :process_failed}
  def finalize_upload(package_name, version) do
    pakcage_dir = Path.join(@package_dir, "/#{package_name}/#{version}")
    delete_dir = Path.join(@upload_dir, "/#{package_name}/#{version}")

    src_path =
      Path.join(@upload_dir, "/#{package_name}/#{version}/#{package_name}-#{version}.tar.gz")

    dest_path = Path.join(pakcage_dir, "#{package_name}-#{version}.tar.gz")

    with :ok <- File.mkdir(pakcage_dir),
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
