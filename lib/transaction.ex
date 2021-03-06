defmodule Braintree.Transaction do
  @moduledoc """
  Create a new sale.

  To create a transaction, you must include an amount and either a
  payment_method_nonce or a payment_method_token.

  https://developers.braintreepayments.com/reference/response/transaction/ruby
  """

  use Braintree.Construction

  alias Braintree.{HTTP, AddOn}
  alias Braintree.ErrorResponse, as: Error

  @type t :: %__MODULE__{
               add_ons:                            [],
               additional_processor_response:      String.t,
               amount:                             number,
               apple_pay_details:                  String.t,
               avs_error_response_code:            String.t,
               avs_postal_code_response_code:      String.t,
               avs_street_address_response_code:   String.t,
               billing_details:                    Map.t,
               channel:                            String.t,
               coinbase_details:                   String.t,
               created_at:                         String.t,
               credit_card_details:                Map.t,
               currency_iso_code:                  String.t,
               custom_fields:                      Map.t,
               customer_details:                   Map.t,
               cvv_response_code:                  String.t,
               descriptor:                         Map.t,
               disbursement_details:               Map.t,
               discounts:                          [],
               disputes:                           [],
               escrow_status:                      String.t,
               gateway_rejection_reason:           String.t,
               id:                                 String.t,
               merchant_account_id:                String.t,
               order_id:                           String.t,
               payment_instrument_type:            String.t,
               paypal:                             Map.t,
               plan_id:                            String.t,
               processor_authorization_code:       String.t,
               processor_response_code:            String.t,
               processor_response_text:            String.t,
               processor_settlement_response_code: String.t,
               processor_settlement_response_text: String.t,
               purchase_order_number:              String.t,
               recurring:                          String.t,
               refund_ids:                         String.t,
               refunded_transaction_id:            String.t,
               risk_data:                          String.t,
               service_fee_amount:                 number,
               settlement_batch_id:                String.t,
               shipping_details:                   Map.t,
               status:                             String.t,
               status_history:                     String.t,
               subscription_details:               Map.t,
               subscription_id:                    String.t,
               tax_amount:                         number,
               tax_exempt:                         boolean,
               type:                               String.t,
               updated_at:                         String.t,
               voice_referral_number:              String.t
             }

  defstruct add_ons:                            [],
            additional_processor_response:      nil,
            amount:                             0,
            apple_pay_details:                  nil,
            avs_error_response_code:            nil,
            avs_postal_code_response_code:      nil,
            avs_street_address_response_code:   nil,
            billing_details:                    %{},
            channel:                            nil,
            coinbase_details:                   nil,
            created_at:                         nil,
            credit_card_details:                %{},
            currency_iso_code:                  nil,
            custom_fields:                      %{},
            customer_details:                   %{},
            cvv_response_code:                  nil,
            descriptor:                         %{},
            disbursement_details:               nil,
            discounts:                          [],
            disputes:                           [],
            escrow_status:                      nil,
            gateway_rejection_reason:           nil,
            id:                                 nil,
            merchant_account_id:                nil,
            order_id:                           nil,
            payment_instrument_type:            nil,
            paypal:                             %{},
            plan_id:                            nil,
            processor_authorization_code:       nil,
            processor_response_code:            nil,
            processor_response_text:            nil,
            processor_settlement_response_code: nil,
            processor_settlement_response_text: nil,
            purchase_order_number:              nil,
            recurring:                          nil,
            refund_ids:                         nil,
            refunded_transaction_id:            nil,
            risk_data:                          nil,
            service_fee_amount:                 0,
            settlement_batch_id:                nil,
            shipping_details:                   %{},
            status:                             nil,
            status_history:                     nil,
            subscription_details:               %{},
            subscription_id:                    nil,
            tax_amount:                         0,
            tax_exempt:                         false,
            type:                               nil,
            updated_at:                         nil,
            voice_referral_number:              nil

  @doc """
  Use a `payment_method_nonce` or `payment_method_token` to make a one time
  charge against a payment method.

  ## Example

      {:ok, transaction} = Transaction.sale(%{
        amount: "100.00",
        payment_method_nonce: @payment_method_nonce,
        options: %{submit_for_settlement: true}
      })

      transaction.status # "settling"
  """
  @spec sale(Map.t) :: {:ok, t} | {:error, Error.t}
  def sale(params) do
    sale_params = Map.merge(params, %{type: "sale"})

    case HTTP.post("transactions", %{transaction: sale_params}) do
      {:ok, %{"transaction" => transaction}} ->
        {:ok, construct(transaction)}
      {:error, %{"api_error_response" => error}} ->
        {:error, Error.construct(error)}
    end
  end

  @doc """
  Use a `transaction_id` and optional `amount` to settle the transaction.
  Use this if `submit_for_settlement` was false while creating the charge using sale.

  ## Example

      {:ok, transaction} = Transaction.submit_for_settlement("123", %{amount: "100"})
      transaction.status # "settling"
  """
  @spec submit_for_settlement(String.t, Map.t) :: {:ok, t} | {:error, Error.t}
  def submit_for_settlement(transaction_id, params) do
    case HTTP.put("transactions/#{transaction_id}/submit_for_settlement", %{transaction: params}) do
      {:ok, %{"transaction" => transaction}} ->
        {:ok, construct(transaction)}
      {:error, %{"api_error_response" => error}} ->
        {:error, Error.construct(error)}
      {:error, :not_found} ->
        {:error, Error.construct(%{"message" => "transaction id is invalid"})}
    end
  end

  @doc """
  Use a `transaction_id` and optional `amount` to issue a refund
  for that transaction

  ## Example

      {:ok, transaction} = Transaction.refund("123", %{amount: "100.00"})

      transaction.status # "refunded"
  """
  @spec refund(String.t, Map.t) :: {:ok, t} | {:error, Error.t}
  def refund(transaction_id, params) do
    case HTTP.post("transactions/#{transaction_id}/refund", %{transaction: params}) do
      {:ok, %{"transaction" => transaction}} ->
        {:ok, construct(transaction)}
      {:error, %{"api_error_response" => error}} ->
        {:error, Error.construct(error)}
      {:error, :not_found} ->
        {:error, Error.construct(%{"message" => "transaction id is invalid"})}
    end
  end

  @doc """
  Use a `transaction_id` to issue a void for that transaction

  ## Example

      {:ok, transaction} = Transaction.void("123")

      transaction.status # "voided"
  """
  @spec void(String.t) :: {:ok, t} | {:error, Error.t}
  def void(transaction_id) do
    case HTTP.put("transactions/#{transaction_id}/void", %{}) do
      {:ok, %{"transaction" => transaction}} ->
        {:ok, construct(transaction)}
      {:error, %{"api_error_response" => error}} ->
        {:error, Error.construct(error)}
      {:error, :not_found} ->
        {:error, Error.construct(%{"message" => "transaction id is invalid"})}
    end
  end

  @doc """
  Find an existing transaction by `transaction_id`

  ## Example

      {:ok, transaction} = Transaction.find("123")
  """
  @spec find(String.t) :: {:ok, t} | {:error, Error.t}
  def find(transaction_id) do
    case HTTP.get("transactions/#{transaction_id}") do
      {:ok, %{"transaction" => transaction}} ->
        {:ok, construct(transaction)}
      {:error, %{"api_error_response" => error}} ->
        {:error, Error.construct(error)}
      {:error, :not_found} ->
        {:error, Error.construct(%{"message" => "transaction id is invalid"})}
    end
  end

  @doc """
  Convert a map into a Transaction struct.

  Add_ons are converted to a list of structs as well.

  ## Example

      transaction = Braintree.Transaction.construct(%{"subscription_id" => "subxid",
                                                      "status" => "submitted_for_settlement"})
  """
  @spec construct(Map.t | [Map.t]) :: t | [t]
  def construct(map) when is_map(map) do
    transaction = super(map)
    %{transaction | add_ons: AddOn.construct(transaction.add_ons)}
  end
  def construct(list) when is_list(list),
    do: Enum.map(list, &construct/1)
end
