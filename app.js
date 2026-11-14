(function () {
  'use strict';

  var cfg = window.SYNCPULSE_LINKS_CONFIG;
  var root = document.getElementById('app');
  var CACHE_KEY = 'syncpulse_links_cache_v1';

  // Conteúdo de reserva caso o Supabase esteja fora do ar e não haja cache.
  var FALLBACK = {
    profile: { name: 'Kadson Pedro', bio: 'Fundador da SyncPulse' },
    sections: [
      { title: 'PedagoFlow', items: [
        { label: 'PedagoFlow — app, WhatsApp e extensão', url: 'https://pedagoflow.syncpulse.com.br', bg_color: '#2563eb', text_color: '#ffffff' }
      ] },
      { title: 'Contato', items: [
        { label: 'WhatsApp', url: 'https://wa.me/5592994314016', bg_color: '#25d366', text_color: '#0b1b46' },
        { label: 'E-mail', url: 'mailto:contato@syncpulse.com.br', bg_color: '#dbeafe', text_color: '#0b1b46' },
        { label: 'Site', url: 'https://www.syncpulse.com.br', bg_color: '#dbeafe', text_color: '#0b1b46' }
      ] }
    ]
  };

  function rest(path) {
    return fetch(cfg.supabaseUrl + '/rest/v1/' + path, {
      headers: { apikey: cfg.supabaseAnonKey, Authorization: 'Bearer ' + cfg.supabaseAnonKey }
    }).then(function (r) {
      if (!r.ok) throw new Error('HTTP ' + r.status);
      return r.json();
    });
  }

  function load() {
    return Promise.all([
      rest('syncpulse_links_profile?select=*&id=eq.1'),
      rest('syncpulse_links_sections?select=id,title,position,active&active=eq.true&order=position.asc,created_at.asc'),
      rest('syncpulse_links_items?select=id,section_id,label,url,bg_color,text_color,position,active&active=eq.true&order=position.asc,created_at.asc')
    ]).then(function (res) {
      var profile = res[0][0] || FALLBACK.profile;
      var sections = res[1].map(function (s) {
        s.items = res[2].filter(function (it) { return it.section_id === s.id; });
        return s;
      });
      return { profile: profile, sections: sections };
    });
  }

  function show(data) {
    window.SyncPulseLinks.render(root, data);
    root.setAttribute('aria-busy', 'false');
    var p = data.profile || {};
    if (p.page_title || p.name) document.title = p.page_title || (p.name + ' | SyncPulse');
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta && p.bg_color) meta.setAttribute('content', p.bg_color);
  }

  var cached = null;
  try { cached = JSON.parse(localStorage.getItem(CACHE_KEY) || 'null'); } catch (e) { cached = null; }
  if (cached && cached.profile) show(cached);

  load().then(function (data) {
    show(data);
    try { localStorage.setItem(CACHE_KEY, JSON.stringify(data)); } catch (e) { /* sem espaço */ }
  }).catch(function () {
    if (!cached) show(FALLBACK);
  });
})();
