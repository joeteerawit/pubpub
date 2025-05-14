defmodule Pubpub.Packages.Upload do
  require Logger

  @upload_dir "priv/packages/uploads"

  @spec perform(map()) :: {:ok, :upload_completed} | {:error, :upload_failed}
  def perform(%{"file" => upload, "package_name" => package_name, "version" => version})
      when is_map(upload) do
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

  def perform(_), do: {:error, :invalid_params}
end
