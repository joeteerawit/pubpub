defmodule Pubpub.Packages do
  @spec get_all_versions(String.t()) :: {:ok, map()} | {:error, :not_found}
  defdelegate get_all_versions(package_name), to: Pubpub.Packages.ListAllVersion, as: :perform

  @spec get_version_metadata(String.t(), String.t()) :: {:ok, map()} | {:error, :not_found}
  defdelegate get_version_metadata(package_name, version),
    to: Pubpub.Packages.GetVersionMetadata,
    as: :perform

  @spec get_archive_path(String.t(), String.t()) :: {:ok, String.t()} | {:error, :not_found}
  defdelegate get_archive_path(package_name, version),
    to: Pubpub.Packages.GetArchivePath,
    as: :perform

  @spec upload(map()) :: {:ok, :upload_completed} | {:error, :upload_failed}
  defdelegate upload(params), to: Pubpub.Packages.Upload, as: :perform

  @spec finalize_upload(String.t(), String.t()) ::
          {:ok, :process_completed} | {:error, :process_failed}
  defdelegate finalize_upload(package_name, version),
    to: Pubpub.Packages.FinalizeUpload,
    as: :perform
end
