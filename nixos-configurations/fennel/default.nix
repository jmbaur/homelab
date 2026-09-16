{
  config,
  lib,
  pkgs,
  ...
}:
let
  # https://huggingface.co/unsloth/Qwen3.8-27B-GGUF
  modelRepo = "unsloth/Qwen3.8-27B-GGUF";

  # llama-server runs as a router (no top-level --model), which is the shape
  # pi's llama.cpp provider expects: its /llama and /model pickers list what
  # GET /models advertises and can only route to presets. Section names here
  # become the model IDs pi displays.
  modelsPreset = pkgs.writeText "llama-models.ini" (
    lib.generators.toINI { } {
      "*" = {
        gpu-layers = 999;
        # Qwen3.8-27B is natively 262144 tokens, and Thor's unified memory holds
        # the whole window without quantizing the KV cache: only 16 of its 64
        # layers use full attention, the rest are Gated DeltaNet.
        ctx-size = 262144;
        # pi needs the model's jinja chat template to emit and parse tool calls.
        jinja = true;
        # Every agent turn resends a long, mostly unchanged prefix. Reuse it
        # across edits instead of reprocessing from the first changed token.
        cache-reuse = 256;
      };

      "Qwen3.8-27B" = {
        hf-repo = modelRepo;
        hf-file = "Qwen3.8-27B-UD-Q8_K_XL.gguf";
        # mmproj-BF16.gguf sits next to it in the repo and is picked up
        # automatically, so pi sees the model as image-capable.

        # Resident before the first prompt instead of paying a ~30G load on the
        # first request of the day.
        load-on-startup = true;
        # The preset already advertises this model; don't list the file it
        # downloads into LLAMA_CACHE a second time.
        dedup-cache-models = true;

        # pi's llama.cpp provider reports these models as non-reasoning and
        # drops reasoning_content, so thinking would only spend tokens and
        # latency on output nothing ever reads.
        reasoning = "off";
        # Qwen's non-thinking recommendation. The thinking-mode set is
        # temp 1.0 / top-p 0.95 / no presence penalty — switch both together.
        temp = "0.7";
        top-p = "0.8";
        top-k = 20;
        min-p = "0.0";
        presence-penalty = "1.5";

        # The repo ships an MTP head matching the model's mtp_num_hidden_layers,
        # but it lives in a subdirectory, so llama-server's sibling autodetection
        # (which requires a shared directory prefix) won't find it on its own.
        spec-type = "draft-mtp";
        spec-draft-hf = modelRepo;
        model-draft = "MTP/mtp-Qwen3.8-27B-Q4_0.gguf";
      };
    }
  );
in
{
  # cuda (on jetspn) does not currently cross-compile
  nixpkgs.buildPlatform = "aarch64-linux";

  nixpkgs.config = {
    allowUnfreePredicate = pkgs._cuda.lib.allowUnfreeCudaPredicate;
    cudaCapabilities = [ "11.0" ];
    cudaForwardCompat = true;
    cudaSupport = true;
  };

  hardware.nvidia-jetpack = {
    enable = true;
    majorVersion = "7";
    som = "thor-agx";
    carrierBoard = "devkit";
    # Dedicated inference box: pin the clocks rather than letting DVFS ramp on
    # every prompt. Costs idle power and heat.
    maxClock = true;
  };

  boot.kernelPatches = [
    {
      name = "erofs";
      patch = null;
      structuredExtraConfig = {
        EROFS_FS = lib.kernel.yes;
      };
    }
  ];

  hardware.graphics.enable = true;

  users.users.root.initialPassword = "";

  # TODO(jared): track this down
  boot.initrd.allowMissingModules = true;

  # TODO(jared): be more specific
  custom.recovery.targetDisk = "/dev/nvme0n1";

  custom.yggdrasil.peers.radish.allowedTCPPorts = [ config.services.llama-cpp.settings.port ];

  environment.systemPackages = [
    config.services.llama-cpp.package
  ];

  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp.override { cudaSupport = true; };
    openFirewall = false;
    settings = {
      port = 8080;
      host = "::";
      models-preset = modelsPreset;
      # A 27B at full context leaves no room for a second resident model; the
      # router evicts least-recently-used rather than refusing to load.
      models-max = 1;
    };
  };

  # The unit runs under DynamicUser, so it needs the groups that own the Tegra
  # GPU nodes to reach the device at all.
  systemd.services.llama-cpp.serviceConfig.SupplementaryGroups = [
    "video"
    "render"
  ];
}
