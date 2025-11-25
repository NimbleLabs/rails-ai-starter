class PaymentsController < ApplicationController
  before_action :authenticate_user!

  def create_subscription
    if current_user.stripe_customer_id.blank?
      stripe_customer = Stripe::Customer.create(email: current_user.email, name: current_user.name)
      current_user.update(stripe_customer_id: stripe_customer.id)
    else
      stripe_customer = Stripe::Customer.retrieve(current_user.stripe_customer_id)
    end

    price_id = params[:stripe_price_id]

    # this handles if a user changes their mind on payment screen
    if session[:subscription_id].present?
      subscription = Stripe::Subscription.retrieve(session[:subscription_id])
      session[:subscription_id] = nil
      Stripe::Subscription.cancel(subscription.id)
    end

    subscription = Stripe::Subscription.create(
      customer: stripe_customer.id,
      items: [{ price: price_id }],
      payment_behavior: 'default_incomplete',
      payment_settings: { save_default_payment_method: 'on_subscription' },
      expand: ['latest_invoice.payment_intent']
    )

    session[:subscription_id] = subscription.id
    render json: { subscriptionId: subscription.id, clientSecret: subscription.latest_invoice.payment_intent.client_secret }
  end

  def payment_complete
    payment_method_id = params[:payment_method_id]
    @payment_method = Stripe::PaymentMethod.retrieve(payment_method_id)

    payment_intent_id = params[:payment_intent_id]
    @payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)

    subscription_id = params[:subscription_id]
    @subscription = Stripe::Subscription.retrieve(subscription_id)
    current_user.update(stripe_subscription_id: @subscription.id)
    session[:subscription_id] = nil
    @last_credit_card = @payment_method['card']

    credit_card_params = {
      brand: @last_credit_card['brand'],
      country: @last_credit_card['country'],
      exp_month: @last_credit_card['exp_month'],
      exp_year: @last_credit_card['exp_year'],
      last4: @last_credit_card['last4'],
      stripe_id: @payment_method['id']
    }

    @credit_card = CreditCard.new(credit_card_params)
    @credit_card.user = current_user
    # SlackService.system_alert_service.new_customer_event(current_user, @credit_card)

    if @credit_card.save
      render json: { status: 'ok' }
    else
      render json: @credit_card.errors, status: :unprocessable_entity
    end

  end

  def price
    render json: { price: 99 }
  end

  def create_payment_intent

    # if session[:payment_intent_id].present?
    #   payment_intent = Stripe::PaymentIntent.retrieve(session[:payment_intent_id])
    #   render json: { clientSecret: payment_intent.client_secret }
    #   return
    # end

    # Ensure we have a valid amount and product
    amount = params[:amount].to_i * 100
    
    # Create or retrieve Stripe customer
    if current_user.stripe_customer_id.blank?
      stripe_customer = Stripe::Customer.create(email: current_user.email, name: current_user.name)
      current_user.update(stripe_customer_id: stripe_customer.id)
    else
      stripe_customer = Stripe::Customer.retrieve(current_user.stripe_customer_id)
    end

    # Create a PaymentIntent
    payment_intent = Stripe::PaymentIntent.create(
      amount: amount,
      currency: 'usd',
      customer: stripe_customer.id,
      payment_method_types: ['card'],
      setup_future_usage: 'off_session',
      description: 'NimbleAI Client',
      metadata: {
        product: 'NimbleAI',
        user_id: current_user.id
      }
    )

    session[:payment_intent_id] = payment_intent.id

    render json: {
      clientSecret: payment_intent.client_secret
    }
  rescue Stripe::StripeError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def one_time_payment_complete
    session[:payment_intent_id] = nil
    payment_intent_id = params[:payment_intent_id]
    payment_method_id = params[:payment_method_id]
    
    @payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)
    @payment_method = Stripe::PaymentMethod.retrieve(payment_method_id)
    @card = @payment_method['card']

    credit_card_params = {
      brand: @card['brand'],
      country: @card['country'],
      exp_month: @card['exp_month'],
      exp_year: @card['exp_year'],
      last4: @card['last4'],
      stripe_id: @payment_method['id']
    }

    @credit_card = CreditCard.new(credit_card_params)
    @credit_card.user = current_user
    
    # Update user with payment intent ID
    current_user.update(payment_intent_id: payment_intent_id)
    SlackService.system_alert_service.new_customer_event(current_user, @credit_card)

    if @credit_card.save
      render json: { status: 'ok' }
    else
      render json: @credit_card.errors, status: :unprocessable_entity
    end
  end
end
