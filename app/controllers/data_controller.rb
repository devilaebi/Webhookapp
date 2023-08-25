class DataController < ApplicationController
    before_action :verify_webhook_authenticity, only: [:create, :update]

    skip_before_action :verify_authenticity_toke:name => 
    
    def create
        data = Data.new(data_params)

        if data.save
            notify_third_party_apis(data)
            render json: data, status: :created
        else
            render  json: { errors: data.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def update
        data = Data.find(params[:id])

        if data.update(data_params)
            notify_third_party_apis(data)
            render json: data, status: :ok
        else
            render json: { errors: data.errors.full_messages }, status: :unprocessable_entity
        end
    end

    private

    def data_params
        params.require(:data).permit(:name, :content)
    end

    def verify_webhook_authenticity
        provided_secret = request.headers['X-Webhook-Secret']
        expected_secret = Rails.application.secrets.webhook_secret
    
        render json: { error: 'Unauthorized' }, status: :unauthorized unless provided_secret == expected_secret
      end

    def notify_third_party_apis(data)
        third_party_endpoints = ['http://api.example.com/webhook', 'http://anotherapi.com/update']

        third_party_endpoints.each do |endpoint|
            payload = {id: data.id, name: data.name, content: data.content}
            reponse = HTTParty.post(endpoint, body: payload.to_json, headers: { 'Content-Type' => 'application/json}')

            Rails.logger.info("Webhook response from #{endpoint}: #{response.code}")
        end
    end     
 
end
