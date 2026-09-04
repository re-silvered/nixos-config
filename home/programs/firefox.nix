{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.keepassxc ];

    policies = {
      # Extensions
      ExtensionSettings =
        let
          moz = extension:
            "https://addons.mozilla.org/firefox/downloads/latest/${extension}/latest.xpi";
        in
        {
          "uBlock0@raymondhill.net" = {
            install_url = moz "ublock-origin";
            installation_mode = "force_installed";
          };

          "addon@clearurls.xyz" = {
            install_url = moz "clearurls";
            installation_mode = "force_installed";
          };

          "sponsorBlocker@ajay.app" = {
            install_url = moz "sponsorblock";
            installation_mode = "force_installed";
          };

          "deArrow@ajay.app" = {
            install_url = moz "dearrow";
            installation_mode = "force_installed";
          };

          "keepassxc-browser@keepassxc.org" = {
            install_url = moz "keepassxc-browser";
            installation_mode = "force_installed";
          };

          "addon@darkreader.org" = {
            install_url = moz "darkreader";
            installation_mode = "force_installed";
          };

          "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}" = {
            install_url = moz "violentmonkey";
            installation_mode = "force_installed";
          };

          # Bionic Reader omitted until its Firefox extension ID is verified.
        };

      Cookies.Behavior = "reject-tracker-and-partition-foreign";

      DisableFirefoxAccounts = true;
      DisableFormHistory = true;
      DisableMasterPasswordCreation = true;
      DisableSetDesktopBackground = true;
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;

      OfferToSaveLogins = false; # keepass
      PasswordManagerEnabled = false; # keepass once more

      NewTabPage = false;
      DisableAppUpdate = true;
      UserMessaging.SkipOnboarding = true;
      DisableProfileImport = true;
      PromptForDownloadLocation = true;

      EncryptedMediaExtensions.Enabled = true;

      EnableTrackingProtection = {
        Category = "strict";
        Value = true;
        Cryptomining = true;
        Fingerprinting = false;
        SuspectedFingerprinting = true;
        EmailTracking = true;
      };

      FirefoxHome = {
        Highlights = false;
        Search = false;
        Snippets = false;
        SponsoredStories = false;
        SponsoredTopSites = false;
        Stories = false;
        TopSites = false;
      };

      FirefoxSuggest = {
        WebSuggestions = false;
      };

      HardwareAcceleration = true;
      Homepage.StartPage = "previous-session";
      NoDefaultBookmarks = true;
    };

    profiles.default = {
      id = 0;
      isDefault = true;

      settings = {
        "media.hardware-video-decoding.force-enabled" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "media.rdd-ffmpeg.enabled" = true;

        "media.memory_cache_max_size" = 65536;
        "image.mem.decode_bytes_at_a_time" = 32768;
        "network.http.max-persistent-connections-per-server" = 10;

        "browser.translations.enable" = true;
        "javascript.options.wasm_simd" = true;

        "privacy.query_stripping.enabled" = true;
        "privacy.query_stripping.enabled.pbmode" = true;
        "privacy.donottrackheader.enabled" = true;
        "dom.battery.enabled" = false;

        "browser.ml.enable" = false;
        "browser.ml.chat.enabled" = false;
        "browser.ml.chat.sidebar" = false;
        "browser.ml.chat.shortcuts" = false;
        "browser.ml.chat.prompts" = false;

        "pdfjs.enableAltText" = false;
        "pdfjs.enableGuessAltText" = false;

        "browser.ping-centre.telemetry" = false;
      };

      search = {
        force = true;
        default = "google"; # The convenience though....
        engines = {
          "ddg" = {
            definedAliases = [ "@ddg" ];
            urls = [{
              template = "https://duckduckgo.com/?q={searchTerms}&ia=web";
            }];
          };
        };
      };
    };
  };
}