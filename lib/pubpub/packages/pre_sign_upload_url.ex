defmodule Pubpub.Packages.PreSignUploadUrl do
  require Logger

  alias Pubpub.Packages.Signature

  @expiration_minutes 10

  def generate(package_name, version) do
    key = "uploads/#{package_name}-#{version}.tar.gz"
    expires_at = DateTime.utc_now() |> DateTime.add(@expiration_minutes * 60, :second)
    iso_expiry = DateTime.to_iso8601(expires_at)

    policy = %{
      "key" => key,
      "expires" => iso_expiry,
      "max_size" => 10 * 1024 * 1024
    }

    with {:ok, encoded_policy} <- Jason.encode(policy),
         {:ok, signature} <- Signature.sign(encoded_policy) do
      %{
        url: "https://your-upload-endpoint/upload",
        fields: %{
          "key" => key,
          "policy" => Base.encode64(encoded_policy),
          "x-pub-signature" => signature,
          "x-pub-expires" => iso_expiry
        }
      }
    else
      reason ->
        Logger.error("Failed to generate pre-signed upload URL: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
