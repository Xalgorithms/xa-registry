require 'remotes/client'

module Api
  module V1
    class RulesController < ActionController::Base
      def by_ns_name_version
        @rule = Rule.where(ns: params[:ns], name: params[:name], version: params[:version]).first
        if @rule && !@rule.content
          cl = Remotes::Client.new(@rule.repository.url)
          res = cl.get(@rule.public_id, @rule.version) do |content|
            @rule.content = content
            @rule.save
          end
        else
          Rails.logger.warn("? Failed locate rule (ns=#{params[:ns]}; name: #{params[:name]}; version=#{params[:version]})")
        end

        if @rule && @rule.content
          render(json: @rule.content)
        else
          render(nothing: true, status: :not_found)
        end
      end

      def create
        @rule = Rule.create(rule_params.merge(public_id: UUID.generate))
        @rule.repository = Repository.where(public_id: params[:repository_id]).first
        @rule.save
        render(json: { id: @rule.public_id})
      end

      def update
        orule = Rule.where(public_id: params['id']).first
        @rule = Rule.create(rule_params.merge(repository: orule.repository, name: orule.name, ns: orule.ns, public_id: UUID.generate))
        render(json: { id: @rule.public_id })
      end

      def destroy
        Rule.where(public_id: params['id']).first.destroy
        render(nothing: true)
      end

      private

      def rule_params
        params.require(:rule).permit(:ns, :name, :version)
      end
    end
  end
end
