defmodule Pubpub.PubRepo.Packages do
  @moduledoc """
  The Packages context.
  """

  @packages_dir "priv/static/packages"

  @doc """
  Returns a package's metadata including all versions.
  """
  @spec get_package(String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_package(package_name) do
    # In a real implementation, this would use a database
    # For this example, we'll simulate with in-memory data

    if package_exists?(package_name) do
      versions = get_package_versions(package_name)
      latest = List.first(versions)

      {:ok,
       %{
         "name" => package_name,
         "isDiscontinued" => false,
         "latest" => latest,
         "versions" => versions
       }}
    else
      {:error, :not_found}
    end
  end

  @doc """
  Returns a specific version of a package.
  """
  @spec get_package_version(String.t(), String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_package_version(package_name, version) do
    # In a real implementation, this would use a database
    if package_version_exists?(package_name, version) do
      {:ok,
       %{
         "version" => version,
         "archive_url" =>
           "#{PubpubWeb.Endpoint.url()}/packages/#{package_name}/versions/#{version}.tar.gz",
         "pubspec" => %{
           "name" => package_name,
           "version" => version,
           "description" => "A sample package",
           "environment" => %{
             "sdk" => ">=2.12.0 <3.0.0"
           }
         }
       }}
    else
      {:error, :not_found}
    end
  end

  @doc """
  Returns the file system path for a package archive.
  """
  @spec get_package_archive_path(String.t(), String.t()) ::
          {:ok, String.t()} | {:error, :not_found}
  def get_package_archive_path(package_name, version) do
    path = "#{@packages_dir}/#{package_name}/#{version}/#{package_name}-#{version}.tar.gz"

    if File.exists?(path) do
      {:ok, path}
    else
      {:error, :not_found}
    end
  end

  # Private helper functions

  defp package_exists?(package_name) do
    # In a real implementation, this would check a database
    # For this example, we'll just return true for known packages
    package_name in ["example_package", "test_package"]
  end

  defp package_version_exists?(package_name, version) do
    # In a real implementation, this would check a database
    package_exists?(package_name) && version in ["1.0.0", "1.0.1", "1.1.0"]
  end

  defp get_package_versions(package_name) do
    # In a real implementation, this would query a database
    # For this example, we'll simulate with hardcoded data
    versions = [
      %{
        "version" => "1.1.0",
        "retracted" => false,
        "archive_url" =>
          "#{PubpubWeb.Endpoint.url()}/packages/#{package_name}/versions/1.1.0.tar.gz",
        "archive_sha256" => "95cbaad58e2cf32d1aa852f20af1fcda1820ead92a4b1447ea7ba1ba18195d27",
        "pubspec" => %{
          "name" => package_name,
          "version" => "1.1.0",
          "description" => "A sample package",
          "environment" => %{
            "sdk" => ">=2.12.0 <3.0.0"
          }
        }
      },
      %{
        "version" => "1.0.1",
        "retracted" => false,
        "archive_url" =>
          "#{PubpubWeb.Endpoint.url()}/packages/#{package_name}/versions/1.0.1.tar.gz",
        "archive_sha256" => "85dbaad58e2cf32d1aa852f20af1fcda1820ead92a4b1447ea7ba1ba18195d27",
        "pubspec" => %{
          "name" => package_name,
          "version" => "1.0.1",
          "description" => "A sample package",
          "environment" => %{
            "sdk" => ">=2.12.0 <3.0.0"
          }
        }
      },
      %{
        "version" => "1.0.0",
        "retracted" => false,
        "archive_url" =>
          "#{PubpubWeb.Endpoint.url()}/packages/#{package_name}/versions/1.0.0.tar.gz",
        "archive_sha256" => "75abaad58e2cf32d1aa852f20af1fcda1820ead92a4b1447ea7ba1ba18195d27",
        "pubspec" => %{
          "name" => package_name,
          "version" => "1.0.0",
          "description" => "A sample package",
          "environment" => %{
            "sdk" => ">=2.12.0 <3.0.0"
          }
        }
      }
    ]

    versions
  end
end
