/* Auto-enregistrement du statut en liste (compatible Unfold : le bouton
   "Enregistrer" est dans le pied de page, hors du formulaire). */
(function () {
  function form() {
    return document.getElementById("changelist-form");
  }

  function saveNow() {
    var f = form();
    if (!f) return;
    // 1) Cliquer le vrai bouton Enregistrer (même hors formulaire via form="...").
    var btn = document.querySelector('button[name="_save"], input[name="_save"]');
    if (btn) {
      btn.click();
      return;
    }
    // 2) Replis standards.
    if (typeof f.requestSubmit === "function") {
      f.requestSubmit();
    } else {
      f.submit();
    }
  }

  // Délégation : marche même si Unfold re-rend les lignes.
  document.addEventListener("change", function (e) {
    var t = e.target;
    if (!t || t.tagName !== "SELECT") return;
    if (!form() || !form().contains(t)) return;
    var name = t.getAttribute("name") || "";
    if (name === "statut" || name.slice(-7) === "-statut") {
      saveNow();
    }
  });
})();
