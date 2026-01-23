# frozen_string_literal: true

module TwoFactorAuth
  # Generates QR codes for 2FA setup
  class QrCodeGenerator
    ISSUER = "Portfolio Site"

    def initialize(admin_user)
      @admin_user = admin_user
    end

    # Generate QR code as Base64 PNG data URL
    def generate
      return nil unless @admin_user.otp_secret.present?

      provisioning_uri = build_provisioning_uri
      qrcode = RQRCode::QRCode.new(provisioning_uri)

      # Generate PNG as data URL
      png = qrcode.as_png(
        size: 300,
        border_modules: 2,
        module_px_size: 6
      )

      "data:image/png;base64,#{Base64.strict_encode64(png.to_s)}"
    end

    # Generate QR code as SVG
    def generate_svg
      return nil unless @admin_user.otp_secret.present?

      provisioning_uri = build_provisioning_uri
      qrcode = RQRCode::QRCode.new(provisioning_uri)

      qrcode.as_svg(
        color: "000",
        shape_rendering: "crispEdges",
        module_size: 6,
        standalone: true,
        use_path: true
      )
    end

    # Get the provisioning URI (for manual entry)
    def provisioning_uri
      build_provisioning_uri
    end

    # Get the secret key (for manual entry)
    def secret_key
      @admin_user.otp_secret
    end

    private

    def build_provisioning_uri
      @admin_user.otp_provisioning_uri(
        @admin_user.email,
        issuer: ISSUER
      )
    end
  end
end
