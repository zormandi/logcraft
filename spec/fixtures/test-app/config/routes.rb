Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get '/access' => "test#access"
  get '/basic' => "test#basic"
  get '/sql' => "test#sql"
  get '/error' => "test#error"
end
