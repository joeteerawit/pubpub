defmodule Pubpub.Packages.FinalizeUpload do
  require Logger

  @package_dir "priv/packages"
  @upload_dir "priv/packages/uploads"

  @spec perform(String.t(), String.t()) :: {:ok, :process_completed} | {:error, :process_failed}
  def perform(package_name, version) do
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
