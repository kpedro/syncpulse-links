# SyncPulse Links

Página de links ("link na bio") de **Kadson Pedro / SyncPulse**, publicada em `links.syncpulse.com.br` (GitHub Pages).

- Site estático, sem build: `index.html`, `app.js`, `links-render.js`, `links-render.css`, `styles.css`.
- O conteúdo (perfil, seções e botões) vem do Supabase em tempo real e é editado no admin:
  **https://www.syncpulse.com.br/admin/** (repositório `kpedro/site-syncpulse`).
- Enquanto carrega, mostra um esqueleto; se o Supabase falhar, usa o último conteúdo salvo no navegador
  ou uma lista mínima de reserva.

## Dados (Supabase `qrjmvqedoypxmnvfdetg`)

Tabelas `syncpulse_links_profile`, `syncpulse_links_sections`, `syncpulse_links_items`, `syncpulse_links_admins`
e bucket público `syncpulse-links` (foto). Ver `supabase/migrations/`.

- RLS: leitura pública (anon) só do perfil e de seções/links ativos.
- Escrita: apenas usuários autenticados cujo e-mail está em `syncpulse_links_admins`.
- `config.js` contém só a URL do projeto e a chave **anon** (pública por design).

`links-render.js` e `links-render.css` são compartilhados com o admin (`site-syncpulse/admin/`).
Ao alterar o visual, copie os dois arquivos para lá também.

## Testar localmente

```bash
python3 -m http.server 8801
# abra http://localhost:8801/
```
