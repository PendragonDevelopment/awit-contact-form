require 'stripe'

class Charge

  def initialize(key)
    Stripe.api_key = key
  end

  def newOrder(token, amount)

    # Get the credit card details submitted by the form
    token = token

    # Create the charge on Stripe's servers - this will charge the user's card
    begin
      charge = Stripe::Charge.create(
        :amount => amount, # amount in cents, again
        :currency => "usd",
        :source => token,
        :description => "Small potatoes"
      )
    rescue Stripe::CardError => e
      # The card has been declined
    end
    return charge
  end

end