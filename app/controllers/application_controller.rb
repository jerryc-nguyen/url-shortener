class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from StandardError, with: :internal_error

  private

  def not_found(exception)
    render_error(404, Errors::ErrorCodes::RECORD_NOT_FOUND, exception.message)
  end

  def unprocessable_entity(exception)
    render_error(422, Errors::ErrorCodes::VALIDATION_ERROR, exception.record.errors.full_messages)
  end

  def internal_error(exception)
    Rails.logger.error(exception.message)
    Rails.logger.error(exception.backtrace.join("\n"))

    render_error(500, Errors::ErrorCodes::INTERNAL_SERVER_ERROR, 'Something went wrong')
  end

  def render_error(status, code, message, details = {})
    render json: {
      error: {
        code: code,
        message: message,
        details: details
      }
    }, status: status
  end
end
