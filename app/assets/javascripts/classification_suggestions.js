(function() {
  "use strict";

  App.ClassificationSuggestions = {
    panelSelector: ".js-classification-suggestions-tags, .js-classification-suggestions-sdgs",
    initialize: function() {
      $("body").on("click", ".js-suggest-classification", function() {
        App.ClassificationSuggestions.requestSuggestions($(this));
      });

      $("body").on("click", ".js-classification-suggestion", function() {
        App.ClassificationSuggestions.applySuggestion($(this));
      });

      $("body").on("click", ".js-classification-accept-all", function() {
        var $panel = $(this).closest(App.ClassificationSuggestions.panelSelector);

        $panel.find(".js-classification-suggestion").each(function() {
          App.ClassificationSuggestions.applySuggestion($(this));
        });
      });

      $("body").on("click", ".js-classification-dismiss", function() {
        var $panel = $(this).closest(App.ClassificationSuggestions.panelSelector);

        App.ClassificationSuggestions.dismissPanel($panel);
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

      $.ajax({
        url: "/classification_suggestions",
        type: "POST",
        data: $.param(params),
        dataType: "json",
        timeout: 50000,
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
      App.ClassificationSuggestions.resetPanelBody($panel, $panel.data("loading"));
    },
    showError: function($panel, message) {
      if (!$panel.length) {
        return;
      }

      $panel.removeClass("hide");
      App.ClassificationSuggestions.resetPanelBody(
        $panel,
        message || $panel.data("error")
      );
    },
    showEmpty: function($panel) {
      if (!$panel.length) {
        return;
      }

      $panel.removeClass("hide");
      App.ClassificationSuggestions.resetPanelBody($panel, $panel.data("empty"));
    },
    resetPanelBody: function($panel, message) {
      var $body = $panel.find(".js-classification-suggestions-body");

      $body.empty();
      $body.append(App.ClassificationSuggestions.closeButton($panel));
      $body.append($("<p>").text(message));
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

      App.ClassificationSuggestions.fillSuggestionPanel($panel, items);
    },
    renderSdgsPanel: function($form, $panel, sdgs) {
      var items = [];
      var suggestions = App.ClassificationSuggestions.sdgSuggestions($form);

      if (!$panel.length) {
        return;
      }

      sdgs.forEach(function(sdg) {
        var code = typeof sdg === "object" && sdg !== null ? sdg.code : sdg;
        var reason = typeof sdg === "object" && sdg !== null ? sdg.reason : null;

        items.push({
          type: "sdg",
          value: String(code),
          label: App.ClassificationSuggestions.sdgLabel(suggestions, code),
          title: reason
        });
      });

      App.ClassificationSuggestions.fillSuggestionPanel($panel, items);
    },
    fillSuggestionPanel: function($panel, items) {
      var $body;

      if (!items.length) {
        App.ClassificationSuggestions.showEmpty($panel);
        return;
      }

      $body = $panel.find(".js-classification-suggestions-body");
      $panel.removeClass("hide");
      $body.empty();
      $body.append(App.ClassificationSuggestions.closeButton($panel));
      $body.append($("<h3>").text($panel.data("title")));
      $body.append(App.ClassificationSuggestions.suggestionButtons($panel, items));
      $body.append(App.ClassificationSuggestions.panelActions($panel));
    },
    suggestionButtons: function($panel, items) {
      var $list = $("<div>").addClass("classification-suggestion-list");
      var template = $panel.find(".js-classification-suggestion-template").get(0);

      items.forEach(function(item) {
        var $button = $(document.importNode(template.content, true).children);
        $button.attr("data-suggestion-type", item.type);
        $button.attr("data-value", item.value);
        if (item.title) {
          $button.attr("title", item.title);
        }
        $button.find(".js-classification-suggestion-label").text(item.label);
        $list.append($button);
      });

      return $list;
    },
    panelActions: function($panel) {
      return $("<div>")
        .addClass("classification-suggestion-actions")
        .append(
          $("<button>")
            .attr("type", "button")
            .addClass("button js-classification-accept-all")
            .text($panel.data("accept-all"))
        );
    },
    closeButton: function($panel) {
      return $("<button>")
        .attr("type", "button")
        .attr("aria-label", $panel.data("close"))
        .addClass("close-button js-classification-dismiss")
        .html("&times;");
    },
    dismissPanel: function($panel) {
      if (!$panel.length) {
        return;
      }

      $panel.addClass("hide");
      $panel.find(".js-classification-suggestions-body").empty();
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
      var $panel = $button.closest(App.ClassificationSuggestions.panelSelector);

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
      App.ClassificationSuggestions.addListValue($form, "input.js-tag-list", value);
    },
    applySdg: function($form, value) {
      App.ClassificationSuggestions.addListValue(
        $form,
        ".sdg-related-list-selector .input",
        value
      );
    },
    addListValue: function($form, selector, value) {
      var input = $form.find(selector)[0];
      var control = input && input.tomselect;

      if (!control) {
        return;
      }

      if (control.items.indexOf(value) === -1) {
        control.createItem(value);
      }
    },
    afterSuggestionRemoved: function($panel) {
      if (!$panel.length) {
        return;
      }

      if ($panel.find(".js-classification-suggestion").length === 0) {
        App.ClassificationSuggestions.dismissPanel($panel);
      }
    }
  };
}).call(this);
