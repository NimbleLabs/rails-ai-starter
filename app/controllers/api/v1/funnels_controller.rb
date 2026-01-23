class Api::V1::FunnelsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  before_action :set_funnel, only: [:show, :update, :destroy]

  def index
    @funnels = Funnel.order(created_at: :desc)
  end

  def show
    render json: @funnel
  end

  def create
    @funnel = Funnel.new(funnel_params)

    if @funnel.save
      render :show, status: :created
    else
      render json: { errors: @funnel.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @funnel.update(funnel_params)
      render :show, status: :ok
    else
      render json: { errors: @funnel.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @funnel.destroy!
    head :no_content
  end

  def metrics
    funnel_slug = params[:funnel_slug]
    start_date = params[:start_date]
    end_date = params[:end_date]

    metrics = Funnel.funnel_metrics(
      funnel_slug: funnel_slug,
      start_date: start_date,
      end_date: end_date
    )

    lead_count = metrics[:lead_page].to_f

    conversion_rates = {
      lead_to_book_call: calculate_rate(metrics[:book_call_page], lead_count),
      book_call_to_order: calculate_rate(metrics[:order_page], metrics[:book_call_page].to_f),
      order_to_completed: calculate_rate(metrics[:order_completed_page], metrics[:order_page].to_f),
      overall: calculate_rate(metrics[:order_completed_page], lead_count)
    }

    render json: {
      funnels: Funnel.active.select(:id, :name, :slug),
      metrics: metrics,
      conversion_rates: conversion_rates,
      filters: {
        funnel_slug: funnel_slug,
        start_date: start_date,
        end_date: end_date
      }
    }
  end

  private

  def set_funnel
    @funnel = Funnel.find(params[:id])
  end

  def funnel_params
    params.require(:funnel).permit(:name, :description, :active)
  end

  def calculate_rate(numerator, denominator)
    return 0 if denominator.zero?
    ((numerator.to_f / denominator) * 100).round(2)
  end
end
