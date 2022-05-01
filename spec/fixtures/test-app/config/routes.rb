Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get '/basic' => "test#basic"
  get '/sql' => "test#sql"
end
