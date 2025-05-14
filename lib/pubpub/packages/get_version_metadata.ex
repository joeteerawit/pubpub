defmodule Pubpub.Packages.GetVersionMetadata do
  @packages_dir "priv/packages"
  @pubspec_yaml "pubspec.yaml"

  @spec perform(String.t(), String.t()) :: {:ok, map()} | {:error, :not_found}
  def perform(name, version) do
    case extract_package(name, version) do
      {:ok, yaml} -> {:ok, yaml}
      {:error, reason} -> {:error, reason}
    end
  end

  defp extract_package(name, version) do
    path = "#{@packages_dir}/#{name}/#{version}/#{name}-#{version}.tar.gz"

    File.exists?(path)
    |> case do
      true -> extract_metadata_from_archive(path)
      false -> {:error, :not_found}
    end
  end

  defp extract_metadata_from_archive(path) do
    with {:ok, tar_gz_binary} <- File.read(path),
         {:ok, tar_binary} <- gunzip(tar_gz_binary),
         {:ok, files} <- extract_tar_in_memory(tar_binary),
         {:ok, yaml_content} <- find_yaml_in_files(files),
         {:ok, yaml} <- parse_yaml(yaml_content) do
      {:ok, yaml}
    else
      {:error, :yaml_not_found} -> {:error, :yaml_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  defp gunzip(binary) do
    try do
      decompressed = :zlib.gunzip(binary)
      {:ok, decompressed}
    rescue
      _ -> {:error, :invalid_gzip}
    end
  end

  defp extract_tar_in_memory(tar_binary) do
    :erl_tar.extract({:binary, tar_binary}, [:memory])
    |> case do
      {:ok, files} -> {:ok, files}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_yaml(content) do
    try do
      YamlElixir.read_from_string(content)
    rescue
      e -> {:error, {:yaml_parse_error, e}}
    end
  end

  defp find_yaml_in_files(files) do
    Enum.map(files, fn {name, content} ->
      {to_string(name), content}
    end)
    |> Enum.find(fn {filename, _} ->
      String.ends_with?(filename, @pubspec_yaml)
    end)
    |> case do
      nil -> {:error, :yaml_not_found}
      {_, yaml_content} -> {:ok, yaml_content}
    end
  end
end
