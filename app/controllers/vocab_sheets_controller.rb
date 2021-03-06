class VocabSheetsController < ApplicationController
  before_action :find_or_create_vocab_sheet, :set_search_query, :footer_content, :set_title
  respond_to :html, :json
  def show
    @size = params[:size].to_i
    @size = session[:vocab_sheet_size].to_i if @size.zero?
    @size = 4 if @size.zero?
    session[:vocab_sheet_size] = @size
  end

  def update # rubocop:disable Metrics/AbcSize
    @sheet.name = params[:vocab_sheet][:name]
    if @sheet.save
      flash[:notice] = t('vocab_sheet.sheet.update_success')
    else
      flash[:error] = t('vocab_sheet.sheet.update_failure')
    end
    if request.xhr?
      flash[:notice] = nil
      flash[:error] = nil
      render json: @sheet
    else
      respond_with_json_or_redirect(@sheet)
    end
  end

  def destroy
    if @sheet.destroy
      session[:vocab_sheet_id] = nil
      flash[:notice] = t('vocab_sheet.delete_success')
    else
      flash[:error] = t('vocab_sheet.delete_failure')
    end
    redirect_back_or_default
  end

  private

  def set_title
    @title = @sheet.name
  end
end
