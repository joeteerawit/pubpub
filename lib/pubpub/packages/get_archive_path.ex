defmodule Pubpub.Packages.GetArchivePath do
  @packages_dir "priv/packages"

  @spec perform(String.t(), String.t()) :: {:ok, String.t()} | {:error, :not_found}
  def perform(package_name, version) do
    path = "#{@packages_dir}/#{package_name}/#{version}/#{package_name}-#{version}.tar.gz"

    if File.exists?(path) do
      {:ok, path}
    else
      {:error, :not_found}
    end
  end
end
