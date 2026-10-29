(function() {
  "use strict";

  App.ClassificationSuggestions = {
    initialize: function() {
      $("body").on("click", ".js-suggest-classification", function() {
        App.ClassificationSuggestions.requestSuggestions($(this));
      });

      $("body").on("click", ".js-classification-suggestion", function() {
        App.ClassificationSuggestions.applySuggestion($(this));
      });

      $("body").on("click", ".js-classification-accept-all", function() {
        var $panel = $(this).closest(
          ".js-classification-suggestions-tags, .js-classification-suggestions-sdgs"
        );

        $panel.find(".js-classification-suggestion").each(function() {
          App.ClassificationSuggestions.applySuggestion($(this));
        });
      });
    },
    requestSuggestions: function($button) {
      var $form = $button.closest("form");
      var resourceType = $button.data("resource-type");
      var $tagsPanel = $form.find(".js-classification-suggestions-tags");
      var $sdgsPanel = $form.find(".js-classification-suggestions-sdgs");
      var params;

      $button.prop("disabled", true);
      $button.addClass("is-loading");
      App.ClassificationSuggestions.showLoading($tagsPanel);
      App.ClassificationSuggestions.showLoading($sdgsPanel);

      if (typeof CKEDITOR !== "undefined") {
        for (var name in CKEDITOR.instances) {
          if (Object.prototype.hasOwnProperty.call(CKEDITOR.instances, name)) {
            CKEDITOR.instances[name].updateElement();
          }
        }
      }

      params = $form.serializeArray().filter(function(item) {
        return item.name !== "_method";
      });
      params.push({ name: "resource_type", value: resourceType });
      params.push({ name: "max_suggestions", value: 6 });

      $.ajax({
        url: "/classification_suggestions",
        type: "POST",
        data: $.param(params),
        dataType: "json",
        success: function(data) {
          App.ClassificationSuggestions.renderResponse($form, data);
        },
        error: function() {
          App.ClassificationSuggestions.showError($tagsPanel);
          App.ClassificationSuggestions.showError($sdgsPanel);
        },
        complete: function() {
          $button.prop("disabled", false);
          $button.removeClass("is-loading");
        }
      });
    },
    showLoading: function($panel) {
      if (!$panel.length) {
        return;
      }

      $panel.removeClass("hide");
      $panel.find(".js-classification-suggestions-body").text($panel.data("loading"));
    },
    showError: function($panel, message) {
      if (!$panel.length) {
        return;
      }

      $panel.removeClass("hide");
      $panel.find(".js-classification-suggestions-body").text(
        message || $panel.data("error")
      );
    },
    showEmpty: function($panel) {
      if (!$panel.length) {
        return;
      }

      $panel.removeClass("hide");
      $panel.find(".js-classification-suggestions-body").text($panel.data("empty"));
    },
    renderResponse: function($form, data) {
      var $tagsPanel = $form.find(".js-classification-suggestions-tags");
      var $sdgsPanel = $form.find(".js-classification-suggestions-sdgs");
      var errors = data.errors || [];
      var categories = data.categories || [];
      var tags = data.tags || [];
      var sdgs = data.sdgs || [];
      var errorMessage;

      if (errors.length) {
        errorMessage = errors.join(" ");
        App.ClassificationSuggestions.showError($tagsPanel, errorMessage);
        App.ClassificationSuggestions.showError($sdgsPanel, errorMessage);
        return;
      }

      App.ClassificationSuggestions.renderTagsPanel($tagsPanel, categories, tags);
      App.ClassificationSuggestions.renderSdgsPanel($form, $sdgsPanel, sdgs);
    },
    renderTagsPanel: function($panel, categories, tags) {
      var $body;
      var items = [];

      if (!$panel.length) {
        return;
      }

      categories.forEach(function(name) {
        items.push({ type: "category", value: name, label: name });
      });
      tags.forEach(function(name) {
        items.push({ type: "tag", value: name, label: name });
      });

      if (!items.length) {
        App.ClassificationSuggestions.showEmpty($panel);
        return;
      }

      $body = $panel.find(".js-classification-suggestions-body");
      $panel.removeClass("hide");
      $body.empty();
      $body.append($("<h3>").text($panel.data("title")));
      $body.append(App.ClassificationSuggestions.suggestionButtons(items));
      $body.append(App.ClassificationSuggestions.acceptAllButton($panel.data("accept-all")));
    },
    renderSdgsPanel: function($form, $panel, sdgs) {
      var $body;
      var items = [];
      var suggestions = App.ClassificationSuggestions.sdgSuggestions($form);

      if (!$panel.length) {
        return;
      }

      sdgs.forEach(function(code) {
        items.push({
          type: "sdg",
          value: String(code),
          label: App.ClassificationSuggestions.sdgLabel(suggestions, code)
        });
      });

      if (!items.length) {
        App.ClassificationSuggestions.showEmpty($panel);
        return;
      }

      $body = $panel.find(".js-classification-suggestions-body");
      $panel.removeClass("hide");
      $body.empty();
      $body.append($("<h3>").text($panel.data("title")));
      $body.append(App.ClassificationSuggestions.suggestionButtons(items));
      $body.append(App.ClassificationSuggestions.acceptAllButton($panel.data("accept-all")));
    },
    suggestionButtons: function(items) {
      var $list = $("<div>").addClass("classification-suggestion-list");

      items.forEach(function(item) {
        var $button = $("<button>")
          .attr("type", "button")
          .addClass("button hollow classification-suggestion-button js-classification-suggestion")
          .attr("data-suggestion-type", item.type)
          .attr("data-value", item.value)
          .text(item.label + " »");

        $list.append($button);
      });

      return $list;
    },
    acceptAllButton: function(label) {
      return $("<button>")
        .attr("type", "button")
        .addClass("button js-classification-accept-all")
        .text(label);
    },
    sdgSuggestions: function($form) {
      var raw = $form.find(".sdg-related-list-selector .input").data("suggestions-list");

      if (!raw) {
        return [];
      }

      if (typeof raw === "string") {
        try {
          return JSON.parse(raw);
        } catch (error) {
          return [];
        }
      }

      return raw;
    },
    sdgLabel: function(suggestions, code) {
      var match;
      var codeString = String(code);

      match = suggestions.find(function(item) {
        return String(item.value) === codeString;
      });

      if (match && match.title) {
        return codeString + " " + match.title;
      }

      if (match && match.display_text) {
        return match.display_text;
      }

      return codeString;
    },
    applySuggestion: function($button) {
      var type = $button.data("suggestion-type");
      var value = String($button.data("value"));
      var $form = $button.closest("form");
      var $panel = $button.closest(
        ".js-classification-suggestions-tags, .js-classification-suggestions-sdgs"
      );

      if (type === "category") {
        App.ClassificationSuggestions.applyCategory($form, value);
      } else if (type === "tag") {
        App.ClassificationSuggestions.applyTag($form, value);
      } else if (type === "sdg") {
        App.ClassificationSuggestions.applySdg($form, value);
      }

      $button.remove();
      App.ClassificationSuggestions.afterSuggestionRemoved($panel);
    },
    applyCategory: function($form, value) {
      var $checkbox = $form.find(".js-tag-category").filter(function() {
        return String($(this).data("list-value")) === value;
      });

      if ($checkbox.length) {
        if (!$checkbox.prop("checked")) {
          $checkbox.prop("checked", true).trigger("change");
        }
        return;
      }

      App.ClassificationSuggestions.applyTag($form, value);
    },
    applyTag: function($form, value) {
      var amsify = $form.find("input.js-tag-list").data("amsifyListField");

      if (!amsify) {
        return;
      }

      if (amsify.settings.tagLimit > 0 &&
          amsify.tagNames.length >= amsify.settings.tagLimit) {
        return;
      }

      if (!amsify.isPresent(value)) {
        amsify.addTag(value);
      }
    },
    applySdg: function($form, value) {
      var amsify = $form.find(".sdg-related-list-selector .input").data("amsifyListField");

      if (!amsify) {
        return;
      }

      if (!amsify.isPresent(value)) {
        amsify.addTag(value);
      }
    },
    afterSuggestionRemoved: function($panel) {
      if (!$panel.length) {
        return;
      }

      if ($panel.find(".js-classification-suggestion").length === 0) {
        $panel.addClass("hide");
        $panel.find(".js-classification-suggestions-body").empty();
      }
    }
  };
}).call(this);
