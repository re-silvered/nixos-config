{
  programs.nixcord.config.plugins = {
    anonymiseFileNames.enable = true;
    betterFolders.enable = true;
    betterGifAltText.enable = true;
    betterGifPicker.enable = true;
    betterSessions.enable = true;
    biggerStreamPreview.enable = true;
    callTimer.enable = true;
    clearUrls.enable = true;
    colorSighted.enable = true;
    concatenatedComponentExtractor.enable = true;
    crashHandler.enable = true;
    customRpc.enable = true;
    dearrow.enable = true;
    experiments.enable = true;
    expressionCloner.enable = true;
    fakeNitro.enable = true;
    fixImagesQuality.enable = true;
    fixSpotifyEmbeds.enable = true;
    fixYoutubeEmbeds.enable = true;
    forceOwnerCrown.enable = true;
    gameActivityToggle.enable = true;
    gifPaste.enable = true;
    iLoveSpam.enable = true;
    imageZoom.enable = true;
    implicitRelationships.enable = true;
    memberCount.enable = true;
    messageLatency = {
      enable = true;
      showMillis = true;
    };
    messageLogger = {
      enable = true;
      ignoreSelf = true;
      collapseDeleted = true;
    };
    noF1.enable = true;
    noMosaic.enable = true;
    noOnboardingDelay.enable = true;
    noReplyMention.enable = true;
    noTrack.enable = true;
    permissionFreeWill.enable = true;
    permissionsViewer.enable = true;
    pinDms = {
      enable = true;
      userBasedCategoryList = {
        "258052773218746368" = [
          {
            id = "oldPins";
            name = "Pins";
            color = 10070709;
            channels = [ "691199593391718401" "704275081529917450" "908228038083358740" "1488123429218422825" ];
            collapsed = false;
          }
        ];
      };
    };
    platformIndicators.enable = true;
    relationshipNotifier = {
      enable = true;
      notices = true;
    };
    replyTimestamp.enable = true;
    revealAllSpoilers.enable = true;
    reverseImageSearch.enable = true;
    reviewDb = {
      enable = true;
      showWarning = false;
      reviewsDropdownState = true;
    };
    sendTimestamps.enable = true;
    serverInfo.enable = true;
    settings = {
      enable = true;
      settingsLocation = "aboveActivity";
    };
    shikiCodeblocks = {
      enable = true;
      theme = "https://cdn.jsdelivr.net/gh/shikijs/textmate-grammars-themes@bc5436518111d87ea58eb56d97b3f9bec30e6b83/packages/tm-themes/themes/dark-plus.json";
    };
    showConnections.enable = true;
    showHiddenChannels.enable = true;
    showHiddenThings.enable = true;
    showMeYourName = {
      enable = true;
      mode = "nick-user";
    };
    showTimeoutDuration.enable = true;
    silentMessageToggle = {
      enable = true;
    };
    silentTyping.enable = true;
    sortFriends = {
      enable = true;
      showDates = true;
    };
    musicControls = {
      enable = true;
      lyricsProvider = "Spotify";
      showSpotifyControls = true;
      useSpotifyUris = true;
    };
    spotifyShareCommands.enable = true;
    startupTimings.enable = true;
    streamerModeOnStream.enable = true;
    supportHelper.enable = true;
    translate.enable = true;
    typingIndicator = {
      enable = true;
      includeMutedChannels = true;
      includeBlockedUsers = true;
    };
    validReply.enable = true;
    validUser.enable = true;
    vcNarrator = {
      enable = true;
      voice = "Microsoft George - English (United Kingdom)";
      volume = 0.7464788732394366;
      rate = 1.0063380281690142;
      latinOnly = true;
      joinMessage = "{{NICKNAME}} joined";
      leaveMessage = "{{NICKNAME}} left";
      moveMessage = "{{NICKNAME}} moved to {{CHANNEL}}";
      muteMessage = "{{NICKNAME}} Muted";
      unmuteMessage = "{{NICKNAME}} unmuted";
      deafenMessage = "{{NICKNAME}} deafened";
      undeafenMessage = "{{NICKNAME}} undeafened";
    };
    viewIcons = {
      enable = true;
      format = "png";
    };
    voiceDownload.enable = true;
    voiceMessages.enable = true;
    volumeBooster.enable = true;
    whoReacted.enable = true;
    youtubeAdblock.enable = true;
  };
  programs.nixcord.extraConfig.plugins = {
    BANger = {
      source = "https://i.imgur.com/wp5q52C.mp4";
    };
    FavoriteGifSearch = {
      enable = true;
      searchOption = "hostandpath";
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
        discordID = "258052773218746368";
        username = "desilvered";
        profilePhoto = "https://cdn.discordapp.com/avatars/258052773218746368/e9d6fb9363998214a84f26468a021826.png?size=128";
        clientMods = [ "vencord" ];
        warningCount = 0;
        badges = [ ];
        notification = null;
        banInfo = null;
        lastReviewID = 0;
        type = 0;
      };
    };
    showHiddenThings = {
      disableDiscoveryFilters = true;
      disableDisallowedDiscoveryFilters = true;
    };
    translate = {
      showChatBarButton = true;
    };
  };
}
