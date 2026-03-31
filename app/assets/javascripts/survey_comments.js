// Create the global "App" namespace if it doesn't already exist
var App = App || {};

// Use a "module pattern" to define our survey logic
App.SurveyComments = (function() {
  "use strict";

  // --- Private variables ---
  var $wrapper, $slides, $noComments, $prevButton, $nextButton, $counter;
  var totalComments, currentIndex;

  // --- Private function ---
  // The main function to update the view
  function updateView() {
    // Special case: handle "no comments"
    if (totalComments === 0) {
      $noComments.show();
      $prevButton.hide();
      $nextButton.hide();
      $counter.hide();
      return;
    }

    // Hide all slides, then show only the current one
    $slides.hide();
    $slides.eq(currentIndex).show();

    // Update the counter text
    $counter.text('Comment ' + (currentIndex + 1) + ' of ' + totalComments);

    // Disable/enable buttons at the start or end
    $prevButton.prop('disabled', currentIndex === 0);
    $nextButton.prop('disabled', currentIndex === totalComments - 1);
  }

  // --- Public function ---
  // This is the function that `application.js` will call
  function initialize() {
    // 1. Find all the elements
    $wrapper = $('#survey-comments-wrapper');

    // If the survey wrapper isn't on this page, stop running.
    if ($wrapper.length === 0) {
      return;
    }

    $slides = $wrapper.find('.survey-comment-slide');
    $noComments = $wrapper.find('#survey-no-comments');
    $prevButton = $wrapper.find('#survey-prev-button');
    $nextButton = $wrapper.find('#survey-next-button');
    $counter = $wrapper.find('#survey-counter');
    
    totalComments = $slides.length;
    currentIndex = 0;

    // 2. Attach click event handlers
    // We use .off().on() to prevent multiple listeners
    // from being attached on repeated Turbolinks loads.
    $nextButton.off('click.survey').on('click.survey', function() {
      if (currentIndex < totalComments - 1) {
        currentIndex++;
        updateView();
      }
    });

    $prevButton.off('click.survey').on('click.survey', function() {
      if (currentIndex > 0) {
        currentIndex--;
        updateView();
      }
    });

    // 3. Initial load
    updateView();
  }

  // "Reveal" the public initialize function
  return {
    initialize: initialize
  };

})();