# frozen_string_literal: true

require "rails_helper"

RSpec.describe Security::ScannerService do
  describe "#process" do
    context "with brakeman results" do
      let(:results) do
        {
          "warnings" => [
            {
              "warning_type" => "SQL Injection",
              "confidence" => "High",
              "message" => "Possible SQL injection",
              "file" => "app/models/user.rb",
              "line" => 42
            },
            {
              "warning_type" => "XSS",
              "confidence" => "Medium",
              "message" => "Possible XSS vulnerability",
              "file" => "app/views/users/show.html.erb",
              "line" => 10
            }
          ]
        }
      end

      let(:service) { described_class.new(scan_type: "brakeman", results: results) }

      it "creates a security scan" do
        expect { service.process }.to change(SecurityScan, :count).by(1)
      end

      it "creates vulnerabilities" do
        expect { service.process }.to change(Vulnerability, :count).by(2)
      end

      it "sets correct scan attributes" do
        scan = service.process

        expect(scan.scan_type).to eq("brakeman")
        expect(scan.status).to eq("completed")
        expect(scan.scanned_at).to be_present
      end

      it "parses vulnerability severity correctly" do
        scan = service.process
        vulnerabilities = scan.vulnerabilities.order(:created_at)

        expect(vulnerabilities.first.severity).to eq("high")
        expect(vulnerabilities.last.severity).to eq("medium")
      end

      it "parses vulnerability details correctly" do
        scan = service.process
        vuln = scan.vulnerabilities.first

        expect(vuln.title).to eq("SQL Injection")
        expect(vuln.description).to eq("Possible SQL injection")
        expect(vuln.file_path).to eq("app/models/user.rb")
        expect(vuln.line_number).to eq(42)
      end

      it "sends notification for high severity" do
        allow(SecurityMailer).to receive_message_chain(:security_alert, :deliver_later)
        allow(SlackNotifier).to receive(:enabled?).and_return(false)

        service.process

        expect(SecurityMailer).to have_received(:security_alert)
      end
    end

    context "with bundler_audit results" do
      let(:results) do
        {
          "results" => [
            {
              "gem" => {
                "name" => "rails",
                "version" => "7.0.0"
              },
              "advisories" => [
                {
                  "title" => "XSS vulnerability in Rails",
                  "cve" => "CVE-2024-12345",
                  "criticality" => "High",
                  "description" => "A XSS vulnerability exists",
                  "patched_versions" => [ ">= 7.0.1" ]
                }
              ]
            }
          ]
        }
      end

      let(:service) { described_class.new(scan_type: "bundler_audit", results: results) }

      it "creates a security scan" do
        expect { service.process }.to change(SecurityScan, :count).by(1)
      end

      it "creates vulnerabilities with gem info" do
        scan = service.process
        vuln = scan.vulnerabilities.first

        expect(vuln.gem_name).to eq("rails")
        expect(vuln.gem_version).to eq("7.0.0")
        expect(vuln.cve_id).to eq("CVE-2024-12345")
        expect(vuln.patched_versions).to eq(">= 7.0.1")
      end
    end

    context "with empty results" do
      let(:results) { { "warnings" => [] } }
      let(:service) { described_class.new(scan_type: "brakeman", results: results) }

      it "creates a scan with no vulnerabilities" do
        scan = service.process

        expect(scan.vulnerabilities.count).to eq(0)
      end

      it "does not send notification" do
        expect(SecurityMailer).not_to receive(:security_alert)

        service.process
      end
    end

    context "with sensitive data in results" do
      let(:results) do
        {
          "warnings" => [],
          "metadata" => {
            "token" => "token=super-secret",
            "api_key" => "secret-key"
          }
        }
      end
      let(:service) { described_class.new(scan_type: "brakeman", results: results) }

      it "redacts sensitive values in stored raw_results" do
        scan = service.process

        expect(scan.raw_results["metadata"]["token"]).to eq("[REDACTED]")
        expect(scan.raw_results["metadata"]["api_key"]).to eq("[REDACTED]")
      end
    end

    context "with many vulnerabilities" do
      let(:results) do
        {
          "warnings" => Array.new(100) do |i|
            {
              "warning_type" => "Warning #{i}",
              "confidence" => "High",
              "message" => "Message #{i}",
              "file" => "app/models/user.rb",
              "line" => i + 1
            }
          end
        }
      end
      let(:service) { described_class.new(scan_type: "brakeman", results: results) }

      it "stores all vulnerabilities" do
        scan = service.process

        expect(scan.vulnerabilities.count).to eq(100)
      end
    end
  end
end
