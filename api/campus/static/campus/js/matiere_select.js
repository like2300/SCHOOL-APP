/* Sélecteur Matière avec barre de recherche (style Unfold, sans dépendance). */
(function () {
  document.addEventListener("DOMContentLoaded", function () {
    var sel = document.getElementById("id_matiere");
    if (!sel || sel.dataset.searchReady) return;
    // Si Select2 est disponible, l'utiliser (style admin natif).
    try {
      if (window.django && django.jQuery && django.jQuery.fn.select2) {
        django.jQuery(sel).select2({ width: "100%", placeholder: "Tape pour rechercher un cours…" });
        sel.dataset.searchReady = "1";
        return;
      }
    } catch (e) { /* repli ci-dessous */ }

    sel.dataset.searchReady = "1";
    var opts = Array.prototype.map.call(sel.options, function (o) {
      return { value: o.value, label: o.text, selected: o.selected };
    });
    sel.style.display = "none";

    var wrap = document.createElement("div");
    wrap.style.position = "relative";
    wrap.style.maxWidth = "480px";
    var btn = document.createElement("button");
    btn.type = "button";
    btn.className = "bg-white rounded-default shadow-xs text-sm px-3 py-2 w-full text-left flex justify-between items-center dark:bg-base-900";
    var panel = document.createElement("div");
    panel.style.display = "none";
    panel.className = "absolute z-50 left-0 right-0 mt-1 bg-white border border-base-200 rounded-default shadow-lg overflow-hidden dark:bg-base-900 dark:border-base-700";
    var search = document.createElement("input");
    search.type = "text";
    search.placeholder = "Tape pour rechercher un cours…";
    search.className = "w-full px-3 py-2 text-sm border-b border-base-200 dark:bg-base-900 dark:border-base-700";
    search.style.outline = "none";
    var list = document.createElement("div");
    list.style.maxHeight = "220px";
    list.style.overflowY = "auto";
    panel.appendChild(search);
    panel.appendChild(list);
    wrap.appendChild(btn);
    wrap.appendChild(panel);
    sel.parentNode.insertBefore(wrap, sel.nextSibling);

    function label() {
      var cur = opts.find(function (o) { return o.value === sel.value; });
      return cur ? cur.label : "— Choisir une matière —";
    }
    function paintBtn() { btn.innerHTML = "<span>" + label().replace(/</g, "&lt;") + "</span><span>▾</span>"; }
    function paintList(f) {
      list.innerHTML = "";
      var q = (f || "").toUpperCase();
      var n = 0;
      opts.forEach(function (o) {
        if (q && o.label.toUpperCase().indexOf(q) === -1) return;
        n++;
        var b = document.createElement("button");
        b.type = "button";
        b.className = "w-full text-left px-3 py-2 text-sm hover:bg-base-100 dark:hover:bg-base-800" + (o.value === sel.value ? " font-semibold" : "");
        b.textContent = o.label;
        b.addEventListener("click", function () {
          sel.value = o.value;
          sel.dispatchEvent(new Event("change", { bubbles: true }));
          paintBtn();
          close();
        });
        list.appendChild(b);
      });
      if (!n) list.innerHTML = '<div class="px-3 py-2 text-sm opacity-60">Aucun cours trouvé.</div>';
    }
    function open() { panel.style.display = "block"; paintList(""); search.value = ""; setTimeout(function () { search.focus(); }, 0); }
    function close() { panel.style.display = "none"; }
    btn.addEventListener("click", function (e) { e.stopPropagation(); panel.style.display === "block" ? close() : open(); });
    search.addEventListener("input", function () { paintList(search.value); });
    document.addEventListener("click", function (e) { if (!wrap.contains(e.target)) close(); });
    paintBtn();
  });
})();
