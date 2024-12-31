class Api::V1::QuestionsController < ApplicationController
  before_action :set_question, only: [:show, :update]

  # GET /questions
  def index
    @questions = Item.order(:id)
    render json: @questions, status: :ok
  end

  # GET /questions/:id
  def show
    begin
      @item = Item.find(params[:id])

      # Choose the correct strategy based on item type
      strategy = get_strategy_for_item(@item)

      # Render the item using the strategy
      @rendered_item = strategy.render(@item)

      render json: { item: @item, rendered_item: @rendered_item }, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Question not found" }, status: :not_found
    end
  end

  # POST /questions
  def create
    questionnaire_id = params[:questionnaire_id]
    questionnaire = Questionnaire.find(questionnaire_id)

    # Create the new Item (item)
    item = questionnaire.items.build(
      txt: params[:txt],
      item_type: params[:question_type],
      seq: params[:seq],
      break_before: true
    )

    # Add attributes based on the item type
    case item.item_type
    when 'Scale'
      item.weight = params[:weight]
      item.max_label = 'Strongly agree'
      item.min_label = 'Strongly disagree'
      item.max_value = params[:max_value] || 5
    when 'Dropdown'
      item.alternatives = '0|1|2|3|4|5'
    when 'TextArea'
      item.size = '60, 5'
    when 'TextField'
      item.size = '30'
    end

    if item.save
      render json: item, status: :created
    else
      render json: { error: item.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  private

  def set_question
    @item = Item.find(params[:id])
  end

  def get_strategy_for_item(item)
    case item.item_type
    when 'Dropdown'
      Strategies::DropdownStrategy.new
    when 'Scale'
      Strategies::ScaleStrategy.new
    # You can add more strategies as needed
    else
      raise "Strategy for this item type not defined"
    end
  end
end
