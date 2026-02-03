# frozen_string_literal: true

module Api
  module Internal
    # Controller for internal security API endpoints (GitHub Actions integration)
    class SecurityController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_internal_api

      # POST /api/internal/security/brakeman
      def brakeman
        service = Security::ScannerService.new(
          scan_type: "brakeman",
          results: scan_params
        )
        scan = service.process

        render json: {
          success: true,
          scan_id: scan.id,
          vulnerabilities_count: scan.vulnerabilities.count
        }, status: :created
      rescue ActionDispatch::Http::Parameters::ParseError => e
        Rails.logger.error "Invalid JSON for Brakeman scan: #{e.message}"
        render json: { error: "Invalid JSON" }, status: :bad_request
      rescue StandardError => e
        Rails.logger.error "Brakeman scan processing failed: #{e.message}"
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # POST /api/internal/security/bundler_audit
      def bundler_audit
        service = Security::ScannerService.new(
          scan_type: "bundler_audit",
          results: scan_params
        )
        scan = service.process

        render json: {
          success: true,
          scan_id: scan.id,
          vulnerabilities_count: scan.vulnerabilities.count
        }, status: :created
      rescue ActionDispatch::Http::Parameters::ParseError => e
        Rails.logger.error "Invalid JSON for bundler-audit scan: #{e.message}"
        render json: { error: "Invalid JSON" }, status: :bad_request
      rescue StandardError => e
        Rails.logger.error "Bundler audit scan processing failed: #{e.message}"
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def authenticate_internal_api
        token = request.headers["Authorization"]
        token = token.remove("Bearer ") if token

        unless valid_token?(token)
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end

      def valid_token?(token)
        return false if token.blank?

        expected_token = ENV["INTERNAL_API_TOKEN"]
        return false if expected_token.blank?

        ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected_token.to_s)
      end

      def scan_params
        request.request_parameters
      rescue ActionDispatch::Http::Parameters::ParseError
        raise
      end
    end
  end
end
