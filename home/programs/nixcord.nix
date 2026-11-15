{ pkgs, ... }:

let
  # because the bugfix isn't available in nixpkgs yetttt
  electron436 = (pkgs.callPackage
    (pkgs.path + "/pkgs/development/tools/electron/binary/generic.nix")
    { }) "43.6.0" {
      x86_64-linux = "3075c82d0749e136bca77563d4dd24e881714d17d98241fafd02320da5d6e237";
      headers = "1lfm4byj4yw6va7mkj34q1qwdha8x88ns3c605jl0x4k1kfm3xpd";
    };
in
{
  programs.nixcord = {
    enable = true;

    discord.enable = false;
    equibop.enable = true;
    equibop.package = pkgs.equibop.override { electron_43 = electron436; };

    config.plugins = {
      anonymiseFileNames.enable = true;
      betterBackreading.enable = true;
      betterFolders.enable = true;
      betterGifAltText.enable = true;
      betterGifPicker.enable = true;
      betterMutualServers.enable = true;
      betterSessions.enable = true;
      biggerStreamPreview.enable = true;
      callTimer.enable = true;
      clearUrls.enable = true;
      colorSighted.enable = true;
      concatenatedComponentExtractor.enable = true;
      crashHandler.enable = true;
      customRpc.enable = true;
      customTimestamps = {
        formats.enable = false;
      };
      dearrow.enable = true;
      experiments.enable = true;
      expressionManager.enable = true;
      fakeNitro.enable = true;
      fixImagesQuality.enable = true;
      fixSpotifyEmbeds.enable = true;
      fixYoutubeEmbeds.enable = true;
      forceOwnerCrown.enable = true;
      gameActivityToggle.enable = true;
      ghosted.enable = true;
      gifMaker.enable = true;
      gifPaste.enable = true;
      gifProviderSwitcher.enable = true;
      gitHubRepos.enable = true;
      homeTyping.enable = true;
      iLoveSpam.enable = true;
      imageZoom.enable = true;
      implicitRelationships.enable = true;
      memberCount.enable = true;
      mentionAvatars.enable = true;
      messageLatency = {
        enable = true;
        showMillis = true;
      };
      messageLogger = {
        enable = true;
        collapseDeleted = true;
        ignoreSelf = true;
      };
      messageLoggerEnhanced = {
        enable = true;
        hideMessageFromMessageLoggers = true;
        ignoreMutedChannels = true;
        imageCacheDir = "/home/silver/.config/equibop/MessageLoggerData/savedImages";
        logsDir = "/home/silver/.config/equibop/MessageLoggerData";
        saveImages = true;
      };
      moreUserTags = {
        tagSettings = {
          administrator.enable = false;
          chatModerator.enable = false;
          moderator.enable = false;
          moderatorStaff.enable = false;
          owner.enable = false;
          voiceModerator.enable = false;
          webhook.enable = false;
          enable = false;
        };
      };
      musicControls = {
        enable = true;
        lyricsProvider = "Spotify";
        showSpotifyControls = true;
        useSpotifyUris = true;
      };
      newPluginsManager.enable = true;
      noF1.enable = true;
      noMosaic.enable = true;
      noOnboardingDelay.enable = true;
      noReplyMention.enable = true;
      noTrack.enable = true;
      permissionFreeWill.enable = true;
      permissionsViewer.enable = true;
      petpet.enable = true;
      pinDms = {
        enable = true;
        userBasedCategoryList = {
          "258052773218746368" = [
            {
              channels = [ "691199593391718401" "704275081529917450" "908228038083358740" "1488123429218422825" ];
              collapsed = false;
              color = 10070709;
              id = "oldPins";
              name = "Pins";
            }
          ];
        };
      };
      platformIndicators.enable = true;
      polishWording.enable = true;
      relationshipNotifier = {
        enable = true;
        notices = true;
      };
      replyTimestamp.enable = true;
      revealAllSpoilers.enable = true;
      reverseImageSearch.enable = true;
      reviewDb = {
        enable = true;
        reviewsDropdownState = true;
        showWarning = false;
      };
      sendTimestamps.enable = true;
      serverInfo.enable = true;
      settings = {
        enable = true;
        settingsLocation = "aboveActivity";
      };
      shikiCodeblocks.enable = true;
      showConnections.enable = true;
      showHiddenChannels.enable = true;
      showHiddenThings.enable = true;
      showMeYourName = {
        enable = true;
        triggerNameRerender = true;
      };
      showTimeoutDuration.enable = true;
      silentMessageToggle = {
        enable = true;
        silent = false;
      };
      silentTyping.enable = true;
      sortFriends = {
        enable = true;
        showDates = true;
      };
      spotifyShareCommands.enable = true;
      startupTimings.enable = true;
      streamerModeOnStream.enable = true;
      supportHelper.enable = true;
      textReplace = {
        regexRules = [
          {
            find = "";
            name = "";
            onlyIfIncludes = "";
            replace = "";
            scope = "myMessages";
          }
        ];
        stringRules = [
          {
            find = "";
            name = "";
            onlyIfIncludes = "";
            replace = "";
            scope = "myMessages";
          }
        ];
      };
      timezones = {
        enable = true;
        askedTimezone = true;
      };
      toneIndicators.enable = true;
      translate.enable = true;
      translatePlus = {
        enable = true;
        shavian = false;
      };
      typingIndicator = {
        enable = true;
        includeBlockedUsers = true;
        includeMutedChannels = true;
      };
      userVoiceShow.enable = true;
      usrbg.enable = true;
      validReply.enable = true;
      validUser.enable = true;
      vcNarrator = {
        enable = true;
        deafenMessage = "{{NICKNAME}} deafened";
        joinMessage = "{{NICKNAME}} joined";
        latinOnly = true;
        leaveMessage = "{{NICKNAME}} left";
        moveMessage = "{{NICKNAME}} moved to {{CHANNEL}}";
        muteMessage = "{{NICKNAME}} Muted";
        rate = 1.0063380281690142;
        undeafenMessage = "{{NICKNAME}} undeafened";
        unmuteMessage = "{{NICKNAME}} unmuted";
        voice = "Afrikaans espeak-ng";
        volume = 0.7464788732394366;
      };
      viewIcons = {
        enable = true;
        format = "png";
      };
      voiceDownload.enable = true;
      voiceMessages.enable = true;
      volumeBooster.enable = true;
      webScreenShareFixes.enable = true;
      whoReacted.enable = true;
      whosWatching.enable = true;
      wigglyText.enable = true;
      writeUpperCase.enable = true;
      xsOverlay.enable = true;
      youtubeAdblock.enable = true;
    };
    extraConfig.plugins = {
      BANger = {
        source = "https://i.imgur.com/wp5q52C.mp4";
      };
      FavoriteGifSearch = {
        enable = true;
        searchOption = "hostandpath";
      };
      musicRichPresence = {
        showLastFmLogo = true;
      };
      noMosaic = {
        mediaLayoutType = "STATIC";
      };
      pinDms = {
        pinnedDMs = "691199593391718401,1214800619836153867";
        sortDmsByNewestMessage = false;
      };
      reviewDb = {
        user = {
          ID = 63339;
          badges = [ ];
          banInfo = null;
          clientMods = [ "vencord" ];
          discordID = "258052773218746368";
          lastReviewID = 0;
          notification = null;
          profilePhoto = "https://cdn.discordapp.com/avatars/258052773218746368/e9d6fb9363998214a84f26468a021826.png?size=128";
          type = 0;
          username = "desilvered";
          warningCount = 0;
        };
      };
      serverListIndicators = {
        useCompact = false;
      };
      shikiCodeblocks = {
        tryHljs = "SECONDARY";
      };
      showHiddenThings = {
        disableDisallowedDiscoveryFilters = true;
        disableDiscoveryFilters = true;
      };
      translate = {
        showChatBarButton = true;
      };
    };
  };
}

