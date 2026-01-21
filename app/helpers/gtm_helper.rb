module GtmHelper
  def gtm_installed?
    SiteSetting.gtm_id.value.present?
  end

  def gtm_id
    SiteSetting.gtm_id.value
  end

  def gtm_head_tag
    return unless gtm_installed?

    tag.script(nonce: content_security_policy_nonce) do
      raw(<<~JS)
        (function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
        new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
        j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
        'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
        })(window,document,'script','dataLayer','#{gtm_id}');
      JS
    end
  end

  def gtm_body_tag
    return unless gtm_installed?

    content_tag(:noscript) do
      tag.iframe(
        src: "https://www.googletagmanager.com/ns.html?id=#{gtm_id}",
        height: "0",
        width: "0",
        style: "display:none;visibility:hidden"
      )
    end
  end
end
