{
  prometheusAlerts+:: {
    groups+: [{
      name: 'cert-manager',
      rules: [
        {
          alert: 'CertManagerCertExpirySoon',
          expr: |||
            avg by (exported_namespace, namespace, name) (
              certmanager_certificate_expiration_timestamp_seconds - time()
            ) < (%s * 24 * 3600) # 21 days in seconds
          ||| % $._config.certManagerCertExpiryDays,
          'for': '1h',
          labels: {
            severity: 'warning',
          },
          annotations: {
            summary: 'The cert `{{ $labels.name }}` is {{ $value | humanizeDuration }} from expiry, it should have renewed over a week ago.',
            description: 'The domain that this cert covers will be unavailable after {{ $value | humanizeDuration }}. Clients using endpoints that this cert protects will start to fail in {{ $value | humanizeDuration }}.',
            dashboard_url: $._config.grafanaExternalUrl + '/d/TvuRo2iMk/cert-manager',
            // runbook_url: 'https://gitlab.com/uneeq-oss/cert-manager-mixin/-/blob/master/RUNBOOK.md#CertManagerCertExpirySoon',
          },
        },
        {
          alert: 'CertManagerCertNotReady',
          expr: |||
            max by (name, exported_namespace, namespace, condition) (
              certmanager_certificate_ready_status{condition!="True"} == 1
            )
          |||,
          'for': '10m',
          labels: {
            severity: 'critical',
          },
          annotations: {
            summary: 'The cert `{{ $labels.name }}` is not ready to serve traffic.',
            description: 'This certificate has not been ready to serve traffic for at least 10m. If the cert is being renewed or there is another valid cert, the ingress controller _may_ be able to serve that instead.',
            dashboard_url: $._config.grafanaExternalUrl + '/d/TvuRo2iMk/cert-manager',
            // runbook_url: 'https://gitlab.com/uneeq-oss/cert-manager-mixin/-/blob/master/RUNBOOK.md#CertManagerCertNotReady',
          },
        },
        {
          alert: 'CertManagerCertExpiryMetricMissing',
          expr: 'absent(certmanager_certificate_expiration_timestamp_seconds)',
          'for': '10m',
          labels: {
            severity: 'info',
          },
          annotations: {
            summary: 'The metric used to observe cert-manager cert expiry is missing.',
            description: 'We are blind as to whether or not we can alert on certificates expiring. It could also be the case that there have not had any Certificate CRDs created.',
            dashboard_url: $._config.grafanaExternalUrl + '/d/TvuRo2iMk/cert-manager',
            // runbook_url: 'https://gitlab.com/uneeq-oss/cert-manager-mixin/-/blob/master/RUNBOOK.md#CertManagerCertExpiryMetricMissing',
          },
        },
        {
          alert: 'CertManagerHittingRateLimits',
          expr: |||
            sum by (host) (
              rate(certmanager_http_acme_client_request_count{status="429"}[5m])
            ) > 0
          |||,
          'for': '5m',
          labels: {
            severity: 'critical',
          },
          annotations: {
            summary: 'Cert manager hitting LetsEncrypt rate limits.',
            description: 'Depending on the rate limit, cert-manager may be unable to generate certificates for up to a week.',
            dashboard_url: $._config.grafanaExternalUrl + '/d/TvuRo2iMk/cert-manager',
            // runbook_url: 'https://gitlab.com/uneeq-oss/cert-manager-mixin/-/blob/master/RUNBOOK.md#CertManagerHittingRateLimits',
          },
        },
      ],
    }],
  },
}
