defmodule Pubpub.Packages.ListAllVersion do
  @packages_dir "priv/packages"

  @spec perform(String.t()) :: {:ok, map()} | {:error, :not_found}
  def perform(name) do
    "#{@packages_dir}/#{name}"
    |> File.ls()
    |> case do
      {:ok, versions} ->
        {:ok, build_package(name, versions)}

      {:error, :enoent} ->
        {:error, :not_found}
    end
  end

  defp build_package(name, versions) do
    %{"name" => name, "versions" => versions, "latest" => List.last(versions)}
  end
end
