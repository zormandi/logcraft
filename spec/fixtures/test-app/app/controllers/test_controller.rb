class TestController < ApplicationController
  def basic
    logger.info message: 'test message', data: 12345
  end

  def sql
    ActiveRecord::Base.connection.query 'SELECT 1'
    head :ok
  end
end
