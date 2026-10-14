/* ============================================================
   mc.hallenbarter.org — shared scripts
   Particles, nav state, copy buttons, live server status,
   mod list filter, downloads rendering.
   ============================================================ */

(function () {
    "use strict";

    /* ---- site config (edit here) ---- */
    var CONFIG = {
        serverIp: "mc.hallenbarter.org",
        statusApi: "https://api.mcsrvstat.us/3/mc.hallenbarter.org", // null to disable live checks
        statusIntervalMs: 60000,
        seed: "-3628575288029383482"
    };

    /* ---------- tiny helpers ---------- */
    function $(sel) { return document.querySelector(sel); }
    function $all(sel) { return Array.prototype.slice.call(document.querySelectorAll(sel)); }

    /* ---------- starfield particles ---------- */
    function initParticles() {
        var canvas = document.getElementById("particles-canvas");
        if (!canvas || !canvas.getContext) return;
        var ctx = canvas.getContext("2d");
        var w, h, particles = [];
        var COUNT = 70;

        function resize() {
            w = canvas.width = window.innerWidth;
            h = canvas.height = window.innerHeight;
        }
        window.addEventListener("resize", resize);
        resize();

        function Particle() { this.reset(); }
        Particle.prototype.reset = function () {
            this.x = Math.random() * w;
            this.y = Math.random() * h;
            this.size = Math.random() * 2.0 + 0.5;
            this.speedX = (Math.random() - 0.5) * 0.2;
            this.speedY = (Math.random() - 0.5) * 0.2;
            this.opacity = Math.random() * 0.5 + 0.2;
        };
        Particle.prototype.update = function () {
            this.x += this.speedX;
            this.y += this.speedY;
            if (this.x < 0 || this.x > w || this.y < 0 || this.y > h) this.reset();
        };
        Particle.prototype.draw = function () {
            ctx.beginPath();
            ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
            ctx.fillStyle = "rgba(180, 210, 255, " + this.opacity + ")";
            ctx.fill();
        };

        for (var i = 0; i < COUNT; i++) particles.push(new Particle());

        function animate() {
            ctx.clearRect(0, 0, w, h);
            for (var j = 0; j < particles.length; j++) {
                particles[j].update();
                particles[j].draw();
            }
            requestAnimationFrame(animate);
        }
        animate();
    }

    /* ---------- nav active state ---------- */
    function initNav() {
        var path = window.location.pathname.split("/").pop() || "index.html";
        $all(".nav-link[data-page]").forEach(function (a) {
            if (a.getAttribute("data-page") === path) a.classList.add("active");
        });
    }

    /* ---------- copy to clipboard ---------- */
    function initCopyButtons() {
        $all("[data-copy]").forEach(function (btn) {
            btn.addEventListener("click", function () {
                var target = document.querySelector(btn.getAttribute("data-copy"));
                var text = target ? target.getAttribute("data-copy-value") || target.textContent.trim()
                                  : btn.getAttribute("data-copy-value") || CONFIG.serverIp;
                doCopy(text, btn);
            });
        });
    }

    function doCopy(text, btn) {
        function ok() {
            var original = btn.innerHTML;
            btn.innerHTML = '<i class="fas fa-check"></i>';
            btn.style.color = "#4caf50";
            setTimeout(function () {
                btn.innerHTML = original;
                btn.style.color = "";
            }, 1600);
        }
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text).then(ok).catch(function () { fallbackCopy(text, ok); });
        } else {
            fallbackCopy(text, ok);
        }
    }

    function fallbackCopy(text, ok) {
        var ta = document.createElement("textarea");
        ta.value = text;
        ta.style.position = "fixed";
        ta.style.opacity = "0";
        document.body.appendChild(ta);
        ta.select();
        try { document.execCommand("copy"); ok(); } catch (e) { /* give up silently */ }
        document.body.removeChild(ta);
    }

    /* ---------- live server status (mcstatus API, CORS-friendly) ---------- */
    function initStatus() {
        var dot = $("#statusDot"), text = $("#statusText"), meta = $("#statusMeta");
        if (!dot || !text) return; // status widget only exists on index

        function setState(state, label, detail) {
            dot.className = "status-dot" + (state === "offline" ? " offline" : state === "unknown" ? " unknown" : "");
            text.innerHTML = label + (detail ? " <small>" + detail + "</small>" : "");
            if (meta) meta.textContent = "";
        }

        function fetchStatus() {
            if (!CONFIG.statusApi) {
                setState("unknown", "Live status disabled", "static site");
                return;
            }
            var ctrl = typeof AbortController !== "undefined" ? new AbortController() : null;
            var timer = setTimeout(function () { if (ctrl) ctrl.abort(); }, 8000);

            fetch(CONFIG.statusApi, ctrl ? { signal: ctrl.signal } : {})
                .then(function (r) { return r.json(); })
                .then(function (data) {
                    clearTimeout(timer);
                    if (data && data.online) {
                        var players = (data.players && typeof data.players.online === "number") ? data.players.online : "?";
                        var max = (data.players && typeof data.players.max === "number") ? data.players.max : "?";
                        var ver = data.version || "";
                        setState("online", "Online", players + " / " + max + " players");
                        if (meta) meta.textContent = ver ? "Minecraft " + ver : "";
                    } else {
                        setState("offline", "Offline", "server unreachable right now");
                        if (meta) meta.textContent = "last checked " + new Date().toLocaleTimeString();
                    }
                })
                .catch(function () {
                    clearTimeout(timer);
                    setState("unknown", "Status unavailable", "status service not reachable");
                });
        }

        fetchStatus();
        setInterval(fetchStatus, CONFIG.statusIntervalMs);

        var refresh = $("#refreshStatusBtn");
        if (refresh) {
            refresh.addEventListener("click", function (e) {
                e.preventDefault();
                var original = refresh.innerHTML;
                refresh.innerHTML = '<i class="fas fa-spinner fa-spin"></i> checking…';
                fetchStatus();
                setTimeout(function () {
                    refresh.innerHTML = '<i class="fas fa-check"></i> refreshed';
                    setTimeout(function () { refresh.innerHTML = original; }, 1300);
                }, 1200);
            });
        }
    }

    /* ---------- mod list search filter ---------- */
    function initModFilter() {
        var input = $("#modSearch");
        if (!input) return;
        input.addEventListener("input", function () {
            var q = input.value.trim().toLowerCase();
            $all("#modTable tbody tr").forEach(function (row) {
                row.style.display = row.textContent.toLowerCase().indexOf(q) !== -1 ? "" : "none";
            });
        });
    }

    /* ---------- downloads list (rendered from data/backups.json) ---------- */
    function initDownloads() {
        var list = $("#backupsList");
        if (!list) return;

        var statLine = $("#downloadsUpdated");

        fetch("data/backups.json", { cache: "no-store" })
            .then(function (r) {
                if (!r.ok) throw new Error("http " + r.status);
                return r.json();
            })
            .then(function (data) {
                if (data.generatedAt && statLine) {
                    statLine.textContent = "Download index updated " + new Date(data.generatedAt).toLocaleString();
                }
                if (!data.files || !data.files.length) {
                    list.innerHTML = '<div class="notice"><i class="fas fa-info-circle"></i>No downloads available yet.</div>';
                    return;
                }
                list.innerHTML = data.files.map(renderDownload).join("");
            })
            .catch(function () {
                list.innerHTML = '<div class="notice"><i class="fas fa-info-circle"></i>Could not load the download index. '
                    + 'It is generated by <code class="inline">scripts/refresh-downloads.sh</code> — see the site README.</div>';
            });
    }

    function renderDownload(f) {
        var icon = f.type === "mods" ? "mods" : "world";
        var iconFa = f.type === "mods" ? "fa-cubes" : "fa-earth-europe";
        var badge = f.type === "mods" ? "Modpack" : "World backup";
        var size = humanSize(f.sizeBytes);
        return '' +
            '<div class="dl-card">' +
            '  <div class="dl-main">' +
            '    <div class="dl-icon ' + icon + '"><i class="fas ' + iconFa + '"></i></div>' +
            '    <div>' +
            '      <div class="dl-title">' + esc(f.title) + '</div>' +
            '      <div class="dl-sub">' + esc(badge) + (f.date ? ' · ' + esc(f.date) : '') + '</div>' +
            (f.desc ? '<div class="dl-desc">' + esc(f.desc) + '</div>' : '') +
            '    </div>' +
            '  </div>' +
            '  <div class="dl-side">' +
            '    <div class="dl-size">' + size + '<small>' + esc(f.sizeLabel || "") + '</small></div>' +
            '    <a class="btn primary sm" href="' + esc(f.url) + '" download><i class="fas fa-download"></i> Download</a>' +
            '  </div>' +
            '</div>';
    }

    function humanSize(bytes) {
        if (!bytes && bytes !== 0) return "—";
        var units = ["B", "KB", "MB", "GB", "TB"];
        var i = 0, n = bytes;
        while (n >= 1024 && i < units.length - 1) { n /= 1024; i++; }
        return n.toFixed(i === 0 ? 0 : 1) + " " + units[i];
    }

    function esc(s) {
        return String(s).replace(/[&<>"']/g, function (c) {
            return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
        });
    }

    /* ---------- boot ---------- */
    document.addEventListener("DOMContentLoaded", function () {
        initParticles();
        initNav();
        initCopyButtons();
        initStatus();
        initModFilter();
        initDownloads();
    });
})();
