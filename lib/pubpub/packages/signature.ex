defmodule Pubpub.Packages.Signature do
  require Logger

  @secret "your-secret-key"

  @spec verify_signature(binary(), binary()) :: {:error, any()} | {:ok, any()}
  def verify_signature(base64_policy, pub_signature) do
    with {:ok, policy_json} <- Base.decode64(base64_policy),
         {:ok, result} <- Jason.decode(policy_json),
         {:ok, signature} <- sign(policy_json),
         true <- signature == pub_signature do
      {:ok, result}
    else
      reason ->
        Logger.error("Failed to verify signature: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @spec sign(binary()) :: {:ok, binary()}
  def sign(data) do
    sign =
      :crypto.mac(:hmac, :sha256, @secret, data)
      |> Base.encode16(case: :lower)

    {:ok, sign}
  end
end
