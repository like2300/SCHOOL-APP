(function () {
  document.addEventListener("DOMContentLoaded", function () {
    var preset = document.getElementById("id_preset");
    var color = document.getElementById("id_primary_color");
    if (!preset || !color) return;
    preset.addEventListener("change", function () {
      if (preset.value) color.value = preset.value;
    });
    color.addEventListener("input", function () {
      // si la couleur tapée correspond à un preset, le présélectionner
      var opts = preset.options;
      for (var i = 0; i < opts.length; i++) {
        if (opts[i].value.toLowerCase() === color.value.toLowerCase()) {
          preset.selectedIndex = i;
          return;
        }
      }
      preset.selectedIndex = 0;
    });
  });
})();
