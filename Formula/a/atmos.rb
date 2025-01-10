class Atmos < Formula
  desc "Universal Tool for DevOps and Cloud Automation"
  homepage "https://github.com/cloudposse/atmos"
  url "https://github.com/cloudposse/atmos/archive/refs/tags/v1.145.0.tar.gz"
  sha256 "11bf7bc9b37da0183e65349235919ccfdcc19c6b4829f7fb7fbc8bc6c39f4ef9"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "f65166321a658c880f1f0e8f893f43af26d5ba6196bfeb0e61c840b2e43fdda5"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "f65166321a658c880f1f0e8f893f43af26d5ba6196bfeb0e61c840b2e43fdda5"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "f65166321a658c880f1f0e8f893f43af26d5ba6196bfeb0e61c840b2e43fdda5"
    sha256 cellar: :any_skip_relocation, sonoma:        "4b19b325632fcf9432e705a781d5be55f261393ef8093b4000b128fcf7e67a44"
    sha256 cellar: :any_skip_relocation, ventura:       "4b19b325632fcf9432e705a781d5be55f261393ef8093b4000b128fcf7e67a44"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "e2689cd7e281d20c8486927c84fb19eccf9018354b3b3694cd8e4eb692a41e0c"
  end

  depends_on "go" => :build

  conflicts_with "tenv", because: "tenv symlinks atmos binaries"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X 'github.com/cloudposse/atmos/pkg/version.Version=#{version}'")

    generate_completions_from_executable(bin/"atmos", "completion")
  end

  test do
    # create basic atmos.yaml
    (testpath/"atmos.yaml").write <<~YAML
      components:
        terraform:
          base_path: "./components/terraform"
          apply_auto_approve: false
          deploy_run_init: true
          auto_generate_backend_file: false
        helmfile:
          base_path: "./components/helmfile"
          kubeconfig_path: "/dev/shm"
          helm_aws_profile_pattern: "{namespace}-{tenant}-gbl-{stage}-helm"
          cluster_name_pattern: "{namespace}-{tenant}-{environment}-{stage}-eks-cluster"
      stacks:
        base_path: "./stacks"
        included_paths:
          - "**/*"
        excluded_paths:
          - "globals/**/*"
          - "catalog/**/*"
          - "**/*globals*"
        name_pattern: "{tenant}-{environment}-{stage}"
      logs:
        verbose: false
        colors: true
    YAML

    # create scaffold
    mkdir_p testpath/"stacks"
    mkdir_p testpath/"components/terraform/top-level-component1"
    (testpath/"stacks/tenant1-ue2-dev.yaml").write <<~YAML
      terraform:
        backend_type: s3 # s3, remote, vault, static, etc.
        backend:
          s3:
            encrypt: true
            bucket: "eg-ue2-root-tfstate"
            key: "terraform.tfstate"
            dynamodb_table: "eg-ue2-root-tfstate-lock"
            acl: "bucket-owner-full-control"
            region: "us-east-2"
            role_arn: null
          remote:
          vault:

      vars:
        tenant: tenant1
        region: us-east-2
        environment: ue2
        stage: dev

      components:
        terraform:
          top-level-component1: {}
    YAML

    # create expected file
    (testpath/"backend.tf.json").write <<~JSON
      {
        "terraform": {
          "backend": {
            "s3": {
              "workspace_key_prefix": "top-level-component1",
              "acl": "bucket-owner-full-control",
              "bucket": "eg-ue2-root-tfstate",
              "dynamodb_table": "eg-ue2-root-tfstate-lock",
              "encrypt": true,
              "key": "terraform.tfstate",
              "region": "us-east-2",
              "role_arn": null
            }
          }
        }
      }
    JSON

    system bin/"atmos", "terraform", "generate", "backend", "top-level-component1", "--stack", "tenant1-ue2-dev"
    actual_json = JSON.parse(File.read(testpath/"components/terraform/top-level-component1/backend.tf.json"))
    expected_json = JSON.parse(File.read(testpath/"backend.tf.json"))
    assert_equal expected_json["terraform"].to_set, actual_json["terraform"].to_set

    assert_match "Atmos #{version}", shell_output("#{bin}/atmos version")
  end
end
