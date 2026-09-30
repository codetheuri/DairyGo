// DairyGo platform console: a small single-page app for platform operators.
// All data is rendered with textContent (never innerHTML) so user-entered
// names cannot inject markup. The session lives in sessionStorage and ends
// when the tab closes.

const API = '/api/v1';
const TOKEN_KEY = 'dairygo.console.token';
const USER_KEY = 'dairygo.console.user';
const app = document.getElementById('app');

// ---------- session & API ----------

const session = {
  get token() { return sessionStorage.getItem(TOKEN_KEY); },
  get user() {
    try { return JSON.parse(sessionStorage.getItem(USER_KEY) || 'null'); } catch { return null; }
  },
  save(token, user) {
    sessionStorage.setItem(TOKEN_KEY, token);
    sessionStorage.setItem(USER_KEY, JSON.stringify(user));
  },
  clear() {
    sessionStorage.removeItem(TOKEN_KEY);
    sessionStorage.removeItem(USER_KEY);
  },
};

class ApiError extends Error {}

async function api(method, path, body) {
  const headers = { Accept: 'application/json' };
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (session.token) headers.Authorization = `Bearer ${session.token}`;

  const res = await fetch(API + path, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
  let json = null;
  try { json = await res.json(); } catch { /* empty body */ }

  if (res.status === 401 && path !== '/auth/login') {
    session.clear();
    render();
    throw new ApiError('Your session has ended. Please sign in again.');
  }
  if (!res.ok || (json && json.success === false)) {
    let msg = (json && json.message) || `Request failed (${res.status})`;
    if (json && json.errors) {
      msg += ': ' + Object.entries(json.errors).map(([k, v]) => `${k} ${v}`).join('; ');
    }
    throw new ApiError(msg);
  }
  return json ? json.data : null;
}

function qs(params) {
  const q = new URLSearchParams();
  Object.entries(params).forEach(([k, v]) => { if (v !== undefined && v !== null && v !== '') q.set(k, v); });
  const s = q.toString();
  return s ? `?${s}` : '';
}

// ---------- DOM helpers ----------

/** Creates an element. props: class, text, attrs, on* handlers, and plain properties. */
function h(tag, props = {}, ...children) {
  const el = document.createElement(tag);
  for (const [key, value] of Object.entries(props || {})) {
    if (value === undefined || value === null || value === false) continue;
    if (key === 'class') el.className = value;
    else if (key === 'text') el.textContent = value;
    else if (key === 'attrs') Object.entries(value).forEach(([a, v]) => el.setAttribute(a, v));
    else if (key.startsWith('on')) el.addEventListener(key.slice(2).toLowerCase(), value);
    else el[key] = value;
  }
  for (const child of children.flat()) {
    if (child === undefined || child === null || child === false) continue;
    el.append(child instanceof Node ? child : document.createTextNode(String(child)));
  }
  return el;
}

function toast(message, isError = false) {
  const t = document.getElementById('toast');
  t.textContent = message;
  t.className = isError ? 'error' : '';
  t.hidden = false;
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => { t.hidden = true; }, isError ? 6000 : 3000);
}

const fmt = {
  num: (v, d = 0) => Number(v || 0).toLocaleString('en-KE', { minimumFractionDigits: d, maximumFractionDigits: d }),
  kes: (v) => `KES ${Number(v || 0).toLocaleString('en-KE', { maximumFractionDigits: 0 })}`,
  litres: (v) => `${Number(v || 0).toLocaleString('en-KE', { maximumFractionDigits: 1 })} L`,
  date: (v) => (v ? new Date(v).toLocaleDateString('en-KE', { day: '2-digit', month: 'short', year: 'numeric' }) : '—'),
  dateTime: (v) => (v ? new Date(v).toLocaleString('en-KE', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' }) : '—'),
};

function pill(text, kind) {
  return h('span', { class: `pill ${kind || pillKind(text)}`, text });
}

function pillKind(status) {
  switch (String(status).toUpperCase()) {
    case 'ACTIVE': case 'SENT': case 'CREATE': return 'ok';
    case 'SUSPENDED': case 'FAILED': case 'ERROR': case 'VOID': case 'DEACTIVATED': return 'bad';
    case 'INACTIVE': case 'WARN': case 'LOCKED': case 'STATUS': return 'warn';
    case 'UPDATE': return 'info';
    default: return 'neutral';
  }
}

/**
 * Renders a table. columns: [{ label, render(row) -> Node|string, num }].
 * options.onRow(row) makes rows clickable; options.detail(row) adds an expandable row.
 */
function table(columns, rows, options = {}) {
  if (!rows || rows.length === 0) {
    return h('div', { class: 'table-wrap' }, h('div', { class: 'empty', text: options.empty || 'Nothing to show yet.' }));
  }
  const tbody = h('tbody');
  rows.forEach((row) => {
    const tr = h('tr', { class: options.onRow || options.detail ? 'clickable' : '' },
      columns.map((c) => h('td', { class: c.num ? 'num' : '' }, c.render(row))));
    if (options.onRow) tr.addEventListener('click', () => options.onRow(row));
    tbody.append(tr);
    if (options.detail) {
      let open = null;
      tr.addEventListener('click', () => {
        if (open) { open.remove(); open = null; return; }
        open = h('tr', { class: 'detail' }, h('td', { attrs: { colspan: columns.length } }, options.detail(row)));
        tr.after(open);
      });
    }
  });
  return h('div', { class: 'table-wrap' },
    h('table', {}, h('thead', {}, h('tr', {}, columns.map((c) => h('th', { class: c.num ? 'num' : '', text: c.label })))), tbody));
}

function plural(n, word) {
  return `${fmt.num(n)} ${word}${n === 1 ? '' : 's'}`;
}

function pager(meta, onPage) {
  if (!meta || meta.total_pages <= 1) {
    return h('div', { class: 'pager' }, h('span', { text: meta ? plural(meta.total, 'record') : '' }));
  }
  return h('div', { class: 'pager' },
    h('span', { text: `Page ${meta.page} of ${meta.total_pages} · ${plural(meta.total, 'record')}` }),
    h('div', { class: 'actions' },
      h('button', { class: 'small', text: 'Previous', disabled: !meta.has_previous, onclick: () => onPage(meta.page - 1) }),
      h('button', { class: 'small', text: 'Next', disabled: !meta.has_next, onclick: () => onPage(meta.page + 1) })));
}

/**
 * Opens a form dialog. fields: [{ name, label, type, required, options, full, placeholder, value, section }].
 * onSubmit(values) may throw; the error is shown inside the dialog.
 */
function openForm({ title, intro, fields, submitLabel = 'Save', danger = false, onSubmit }) {
  const error = h('p', { class: 'form-error', hidden: true });
  const inputs = {};
  const grid = h('div', { class: 'form-grid' });

  fields.forEach((f) => {
    if (f.section) { grid.append(h('div', { class: 'section-title', text: f.section })); return; }
    let input;
    if (f.type === 'select') {
      input = h('select', { name: f.name, required: f.required }, f.options.map(([v, l]) => h('option', { value: v, text: l })));
      if (f.value !== undefined) input.value = f.value;
    } else if (f.type === 'textarea') {
      input = h('textarea', { name: f.name, required: f.required, rows: 3, placeholder: f.placeholder || '', value: f.value || '' });
    } else {
      input = h('input', { name: f.name, type: f.type || 'text', required: f.required, placeholder: f.placeholder || '', value: f.value || '', autocomplete: 'off' });
      if (f.minlength) input.minLength = f.minlength;
    }
    inputs[f.name] = input;
    grid.append(h('label', { class: `field ${f.full ? 'full' : ''}` }, `${f.label}${f.required ? ' *' : ''}`, input));
  });

  const submit = h('button', { type: 'submit', class: danger ? 'primary danger' : 'primary', text: submitLabel });
  const dialog = h('dialog');
  const form = h('form', {
    onsubmit: async (e) => {
      e.preventDefault();
      error.hidden = true;
      submit.disabled = true;
      const values = {};
      Object.entries(inputs).forEach(([k, el]) => { values[k] = el.value.trim(); });
      try {
        await onSubmit(values);
        dialog.close();
      } catch (err) {
        error.textContent = err.message;
        error.hidden = false;
      } finally {
        submit.disabled = false;
      }
    },
  },
  h('h2', { text: title }),
  intro ? h('p', { class: 'muted small', text: intro }) : null,
  error, grid,
  h('div', { class: 'dialog-actions' },
    h('button', { type: 'button', text: 'Cancel', onclick: () => dialog.close() }), submit));

  dialog.append(form);
  dialog.addEventListener('close', () => dialog.remove());
  document.body.append(dialog);
  dialog.showModal();
  const first = Object.values(inputs)[0];
  if (first) first.focus();
}

/** Removes empty strings so optional fields are sent as absent. */
function compact(values) {
  const out = {};
  Object.entries(values).forEach(([k, v]) => { if (v !== '' && v !== undefined) out[k] = v; });
  return out;
}

// ---------- routing ----------

const routes = [
  { pattern: /^$/, page: overviewPage, nav: 'overview' },
  { pattern: /^saccos$/, page: saccosPage, nav: 'saccos' },
  { pattern: /^saccos\/([^/]+)(?:\/(staff|farmers|activity|errors))?$/, page: saccoPage, nav: 'saccos' },
  { pattern: /^roles$/, page: rolesPage, nav: 'roles' },
  { pattern: /^audit$/, page: auditPage, nav: 'audit' },
  { pattern: /^errors$/, page: errorsPage, nav: 'errors' },
  { pattern: /^sms$/, page: smsPage, nav: 'sms' },
];

function go(path) { location.hash = `#/${path}`; }

async function render() {
  if (!session.token) { loginPage(); return; }
  const path = location.hash.replace(/^#\/?/, '');
  const route = routes.find((r) => r.pattern.test(path)) || routes[0];
  const params = path.match(route.pattern)?.slice(1) || [];

  const main = h('main', { class: 'main' }, h('div', { class: 'loading', text: 'Loading…' }));
  app.replaceChildren(layout(main, route.nav));
  try {
    const content = await route.page(...params);
    main.replaceChildren(content);
  } catch (err) {
    main.replaceChildren(h('div', { class: 'card' }, h('h2', { text: 'Something went wrong' }), h('p', { text: err.message })));
  }
}

function layout(main, active) {
  const link = (key, href, label) => h('a', { href, text: label, class: key === active ? 'active' : '' });
  const user = session.user || {};
  return h('div', { class: 'shell' },
    h('aside', { class: 'sidebar' },
      h('div', { class: 'brand' }, 'DairyGo ', h('span', { text: 'Console' })),
      h('nav', { class: 'nav' },
        link('overview', '#/', 'Overview'),
        link('saccos', '#/saccos', 'Saccos'),
        link('roles', '#/roles', 'Roles & permissions'),
        link('audit', '#/audit', 'Audit trail'),
        link('errors', '#/errors', 'Errors'),
        link('sms', '#/sms', 'SMS logs')),
      h('div', { class: 'spacer' }),
      h('div', { class: 'whoami' },
        h('div', { text: `Signed in as ${user.username || ''}` }),
        h('a', { href: '#', text: 'Sign out', onclick: (e) => { e.preventDefault(); session.clear(); render(); } }))),
    main);
}

// ---------- login ----------

function loginPage() {
  const error = h('p', { class: 'form-error', hidden: true });
  const login = h('input', { name: 'login', placeholder: 'Username, email or phone', required: true, autocomplete: 'username' });
  const password = h('input', { name: 'password', type: 'password', placeholder: 'Password', required: true, autocomplete: 'current-password' });
  const submit = h('button', { class: 'primary', type: 'submit', text: 'Sign in' });

  app.replaceChildren(h('div', { class: 'login' }, h('div', { class: 'card' },
    h('h1', { text: 'DairyGo Console' }),
    h('p', { class: 'muted', text: 'For DairyGo platform operators.' }),
    h('form', {
      onsubmit: async (e) => {
        e.preventDefault();
        error.hidden = true;
        submit.disabled = true;
        try {
          const data = await api('POST', '/auth/login', { login: login.value.trim(), password: password.value });
          const user = data.user || {};
          if (!user.is_super_user || user.sacco_id) {
            throw new Error('This console is only for DairyGo platform operators. Sacco staff should use the mobile app.');
          }
          session.save(data.access_token, { id: user.id, username: user.username });
          if (!location.hash || location.hash === '#') location.hash = '#/';
          render();
        } catch (err) {
          error.textContent = err.message;
          error.hidden = false;
        } finally {
          submit.disabled = false;
        }
      },
    }, error, login, password, submit))));
  login.focus();
}

// ---------- overview ----------

let overviewCache = null;

async function loadOverview(force = false) {
  if (!overviewCache || force) overviewCache = await api('GET', '/admin/overview');
  return overviewCache;
}

function stat(label, value, hint, alert = false, href) {
  const body = [h('div', { class: 'label', text: label }), h('div', { class: 'value', text: value }), hint ? h('div', { class: 'hint', text: hint }) : null];
  return h('div', { class: `card stat ${alert ? 'alert' : ''}` }, href ? h('a', { href }, body) : body);
}

function saccoColumns() {
  return [
    { label: 'Sacco', render: (s) => h('div', {}, h('div', { text: s.name }), h('div', { class: 'sub', text: s.code })) },
    { label: 'Status', render: (s) => pill(s.status) },
    { label: 'Farmers', num: true, render: (s) => fmt.num(s.active_farmers) },
    { label: 'Staff', num: true, render: (s) => fmt.num(s.staff_count) },
    { label: 'Litres (month)', num: true, render: (s) => fmt.litres(s.month_litres) },
    { label: 'Revenue (month)', num: true, render: (s) => fmt.kes(s.month_revenue_kes) },
    { label: 'Customers owe', num: true, render: (s) => fmt.kes(s.receivables_kes) },
    { label: 'Last collection', render: (s) => fmt.date(s.last_collection) },
  ];
}

async function overviewPage() {
  const o = await loadOverview(true);
  return h('div', {},
    h('div', { class: 'page-head' }, h('h1', { text: 'Platform overview' }),
      h('button', { class: 'primary', text: 'Onboard Sacco', onclick: onboardSacco })),
    h('div', { class: 'stats' },
      stat('Saccos', fmt.num(o.saccos_active), `${o.saccos_total} total · ${o.saccos_suspended} suspended · ${o.saccos_inactive} inactive`),
      stat('Active farmers', fmt.num(o.active_farmers)),
      stat('Staff accounts', fmt.num(o.staff_users)),
      stat('Milk today', fmt.litres(o.today_collected_litres)),
      stat('Milk this month', fmt.litres(o.month_collected_litres)),
      stat('Sales this month', fmt.kes(o.month_sales_revenue_kes)),
      stat('Owed to farmers (month)', fmt.kes(o.month_payout_liability_kes)),
      stat('Customers owe', fmt.kes(o.receivables_kes)),
      stat('Failed requests (24h)', fmt.num(o.failed_requests_24h), 'Tap to review', false, '#/errors'),
      stat('Server errors (24h)', fmt.num(o.server_errors_24h), o.server_errors_24h ? 'Needs attention' : 'All clear', o.server_errors_24h > 0, '#/errors')),
    h('h2', { text: 'Saccos' }),
    table(saccoColumns(), o.saccos, { onRow: (s) => go(`saccos/${s.id}`), empty: 'No Saccos yet. Onboard the first one.' }));
}

// ---------- saccos ----------

async function saccosPage() {
  const o = await loadOverview(true);
  const holder = h('div');
  const search = h('input', { type: 'search', placeholder: 'Search by name or code' });
  const status = h('select', {}, [['', 'All statuses'], ['ACTIVE', 'Active'], ['SUSPENDED', 'Suspended'], ['INACTIVE', 'Inactive']]
    .map(([v, l]) => h('option', { value: v, text: l })));

  const draw = () => {
    const term = search.value.trim().toLowerCase();
    const rows = o.saccos.filter((s) => (!status.value || s.status === status.value)
      && (!term || s.name.toLowerCase().includes(term) || s.code.toLowerCase().includes(term)));
    holder.replaceChildren(table(saccoColumns(), rows, { onRow: (s) => go(`saccos/${s.id}`), empty: 'No matching Saccos.' }));
  };
  search.addEventListener('input', draw);
  status.addEventListener('change', draw);
  draw();

  return h('div', {},
    h('div', { class: 'page-head' }, h('h1', { text: 'Saccos' }),
      h('button', { class: 'primary', text: 'Onboard Sacco', onclick: onboardSacco })),
    h('div', { class: 'filters' }, search, status),
    holder);
}

function onboardSacco() {
  openForm({
    title: 'Onboard a Sacco',
    intro: 'Creates the Sacco and its first administrator, who signs in to the mobile app with these details.',
    submitLabel: 'Create Sacco',
    fields: [
      { section: 'Sacco' },
      { name: 'name', label: 'Sacco name', required: true, full: true },
      { name: 'code', label: 'Code', required: true, placeholder: 'e.g. KIAMBU-DAIRY' },
      { name: 'phone', label: 'Phone' },
      { name: 'email', label: 'Email', type: 'email' },
      { name: 'address', label: 'Address / location' },
      { section: 'First administrator' },
      { name: 'admin_username', label: 'Username', required: true },
      { name: 'admin_email', label: 'Email', type: 'email', required: true },
      { name: 'admin_phone', label: 'Phone' },
      { name: 'admin_password', label: 'Initial password', type: 'password', required: true, minlength: 8 },
    ],
    onSubmit: async (v) => {
      const data = await api('POST', '/admin/saccos', compact({
        name: v.name, code: v.code, phone: v.phone, email: v.email, address: v.address,
        admin_user: compact({ username: v.admin_username, email: v.admin_email, phone: v.admin_phone, password: v.admin_password }),
      }));
      overviewCache = null;
      toast(`${data.sacco.name} is ready`);
      go(`saccos/${data.sacco.id}`);
    },
  });
}

async function saccoPage(id, tab = 'staff') {
  const data = await api('GET', `/admin/saccos/${id}`);
  const sacco = data.sacco;
  const content = h('div', { class: 'loading', text: 'Loading…' });

  const setStatus = (status, verb) => openForm({
    title: `${verb} ${sacco.name}?`,
    intro: status === 'ACTIVE'
      ? 'Staff will be able to sign in and use the app again.'
      : 'All of this Sacco\'s staff are signed out immediately and cannot sign in until it is reactivated. Its data is kept.',
    submitLabel: verb, danger: status !== 'ACTIVE',
    fields: [{ name: 'reason', label: 'Reason (kept in the audit trail)', type: 'textarea', full: true, required: status !== 'ACTIVE' }],
    onSubmit: async (v) => {
      await api('PATCH', `/admin/saccos/${id}/status`, compact({ status, reason: v.reason }));
      overviewCache = null;
      toast(`Sacco ${status.toLowerCase()}`);
      render();
    },
  });

  const edit = () => openForm({
    title: 'Edit Sacco details',
    fields: [
      { name: 'name', label: 'Name', value: sacco.name, required: true, full: true },
      { name: 'phone', label: 'Phone', value: sacco.phone || '' },
      { name: 'email', label: 'Email', type: 'email', value: sacco.email || '' },
      { name: 'address', label: 'Address', value: sacco.address || '', full: true },
    ],
    onSubmit: async (v) => {
      await api('PUT', `/admin/saccos/${id}`, compact(v));
      overviewCache = null;
      toast('Saved');
      render();
    },
  });

  const statusActions = sacco.status === 'ACTIVE'
    ? [h('button', { class: 'danger', text: 'Suspend', onclick: () => setStatus('SUSPENDED', 'Suspend') }),
      h('button', { text: 'Deactivate', onclick: () => setStatus('INACTIVE', 'Deactivate') })]
    : [h('button', { class: 'primary', text: 'Reactivate', onclick: () => setStatus('ACTIVE', 'Reactivate') })];

  const tabs = [['staff', 'Staff'], ['farmers', 'Farmers'], ['activity', 'Activity'], ['errors', 'Errors']];

  const pages = { staff: staffTab, farmers: farmersTab, activity: activityTab, errors: saccoErrorsTab };
  pages[tab](sacco).then((node) => content.replaceChildren(node))
    .catch((err) => content.replaceChildren(h('p', { class: 'form-error', text: err.message })));

  return h('div', {},
    h('div', { class: 'page-head' },
      h('div', {}, h('a', { href: '#/saccos', class: 'small', text: '← All Saccos' }),
        h('h1', {}, sacco.name, ' ', pill(sacco.status)),
        h('div', { class: 'muted small', text: [sacco.code, sacco.phone, sacco.email, sacco.address].filter(Boolean).join(' · ') })),
      h('div', { class: 'actions' }, h('button', { text: 'Edit details', onclick: edit }), statusActions)),
    h('nav', { class: 'tabs' }, tabs.map(([key, label]) =>
      h('a', { href: `#/saccos/${id}/${key}`, text: label, class: key === tab ? 'active' : '' }))),
    content);
}

// ---------- roles & permissions ----------

const PERMISSION_AREAS = [
  ['milk.records', 'Whose records they see'],
  ['milk.collections', 'Milk intake'], ['milk.sales', 'Sales'], ['milk.transfers', 'Transfers'],
  ['milk.spoilage', 'Spoilage'], ['milk.reconciliation', 'Daily balance'], ['milk.prices', 'Milk price'],
  ['members', 'Farmers'], ['customers', 'Customers'], ['dashboard', 'Dashboards'], ['reports', 'Reports'],
  ['users', 'Staff'], ['sacco', 'Sacco settings'], ['notifications', 'SMS'],
];
// Never given to Sacco roles: they reach across Saccos (the API refuses too).
const isPlatformOnly = (name) => name === 'platform.manage' || name === 'users.roles.manage'
  || name === 'permissions.read' || name.startsWith('roles.');

async function rolesPage() {
  const [{ roles }, { permissions }] = await Promise.all([api('GET', '/auth/roles'), api('GET', '/auth/permissions')]);
  const saccoRoles = roles.filter((r) => r.id >= 1 && r.id <= 3).sort((a, b) => a.id - b.id);
  const held = new Map(saccoRoles.map((r) => [r.id, new Set(r.permissions || [])]));
  const usable = permissions.filter((p) => !isPlatformOnly(p.name)).sort((a, b) => a.name.localeCompare(b.name));

  const toggle = async (box, role, perm) => {
    box.disabled = true;
    try {
      if (box.checked) {
        await api('POST', `/auth/roles/${role.id}/permissions`, { permission_name: perm.name });
        held.get(role.id).add(perm.name);
      } else {
        await api('DELETE', `/auth/roles/${role.id}/permissions/${encodeURIComponent(perm.name)}`);
        held.get(role.id).delete(perm.name);
      }
      const what = (perm.description || perm.name).replace(/^Allows /, '');
      toast(`${role.name}: ${box.checked ? 'now allowed' : 'no longer allowed'}: ${what}`);
    } catch (err) {
      box.checked = !box.checked;
      toast(err.message, true);
    } finally { box.disabled = false; }
  };

  const areaOf = (name) => (PERMISSION_AREAS.find(([prefix]) => name.startsWith(prefix + '.')) || [null, 'Other'])[1];
  const areas = [...PERMISSION_AREAS.map(([, label]) => label), 'Other'];
  const tbody = h('tbody');
  areas.forEach((area) => {
    const rows = usable.filter((p) => areaOf(p.name) === area);
    if (!rows.length) return;
    tbody.append(h('tr', { class: 'group' }, h('td', { attrs: { colspan: saccoRoles.length + 1 }, text: area })));
    rows.forEach((perm) => {
      tbody.append(h('tr', {},
        h('td', {}, h('div', { text: (perm.description || perm.name).replace(/^Allows /, '') }), h('div', { class: 'sub', text: perm.name })),
        saccoRoles.map((role) => {
          const box = h('input', { type: 'checkbox', attrs: { 'aria-label': `${role.name}: ${perm.name}` } });
          box.checked = held.get(role.id).has(perm.name);
          box.addEventListener('change', () => toggle(box, role, perm));
          return h('td', { class: 'check' }, box);
        })));
    });
  });

  return h('div', {},
    h('div', { class: 'page-head' }, h('h1', { text: 'Roles & permissions' })),
    h('p', { class: 'muted', text: 'What each Sacco role may do, in every Sacco. A change applies at once on the server; the app shows or hides the matching screens the next time it is opened. Each change is kept in the audit trail.' }),
    h('div', { class: 'table-wrap' },
      h('table', { class: 'matrix' },
        h('thead', {}, h('tr', {}, h('th', { text: 'Permission' }), saccoRoles.map((r) => h('th', { class: 'check', text: r.name })))),
        tbody)));
}

// ---------- sacco tabs ----------

const ROLE_OPTIONS = [['1', 'Sacco Administrator'], ['2', 'Milk Collector'], ['3', 'Board Member / Executive']];

async function staffTab(sacco) {
  const { users } = await api('GET', `/admin/saccos/${sacco.id}/users`);
  const reload = () => render();

  const addStaff = () => openForm({
    title: `Add staff to ${sacco.name}`,
    submitLabel: 'Create account',
    fields: [
      { name: 'first_name', label: 'First name', required: true },
      { name: 'last_name', label: 'Last name', required: true },
      { name: 'username', label: 'Username', required: true },
      { name: 'email', label: 'Email', type: 'email', required: true },
      { name: 'phone', label: 'Phone' },
      { name: 'role_id', label: 'Role', type: 'select', options: ROLE_OPTIONS, value: '2', required: true },
      { name: 'password', label: 'Initial password', type: 'password', required: true, minlength: 8, full: true },
    ],
    onSubmit: async (v) => {
      await api('POST', `/admin/saccos/${sacco.id}/users`, compact({ ...v, role_id: Number(v.role_id) }));
      toast('Staff account created');
      reload();
    },
  });

  const setActive = (u, active) => openForm({
    title: `${active ? 'Reactivate' : 'Deactivate'} ${u.username}?`,
    intro: active ? 'They will be able to sign in again.' : 'They are signed out immediately and cannot sign in.',
    submitLabel: active ? 'Reactivate' : 'Deactivate', danger: !active,
    fields: [{ name: 'reason', label: 'Reason', type: 'textarea', full: true }],
    onSubmit: async (v) => {
      await api('PATCH', `/admin/users/${u.id}/status`, compact({ is_active: active, reason: v.reason }));
      toast('User updated');
      reload();
    },
  });

  const resetPassword = (u) => openForm({
    title: `Reset password for ${u.username}`,
    intro: 'Give the new password to the user securely. Their current sessions end.',
    submitLabel: 'Reset password',
    fields: [{ name: 'new_password', label: 'New password', type: 'password', required: true, minlength: 8, full: true }],
    onSubmit: async (v) => {
      await api('POST', `/admin/users/${u.id}/reset-password`, v);
      toast('Password reset');
      reload();
    },
  });

  const changeRole = (u) => openForm({
    title: `Change role of ${u.username}`,
    intro: 'The new role replaces the current one and applies immediately. Their app shows the new menus the next time it is opened.',
    submitLabel: 'Change role',
    fields: [
      { name: 'role_id', label: 'Role', type: 'select', options: ROLE_OPTIONS, required: true,
        value: (ROLE_OPTIONS.find(([, label]) => label === u.role_name) || ROLE_OPTIONS[1])[0] },
      { name: 'reason', label: 'Reason', type: 'textarea', full: true },
    ],
    onSubmit: async (v) => {
      await api('PUT', `/admin/users/${u.id}/role`, compact({ role_id: Number(v.role_id), reason: v.reason }));
      toast('Role changed');
      reload();
    },
  });

  const remove = (u) => openForm({
    title: `Remove ${u.username} from ${sacco.name}?`,
    intro: 'They are signed out immediately and cannot sign in again. Everything they recorded is kept under their name. This cannot be undone; to let them back in, add a new account.',
    submitLabel: 'Remove account', danger: true,
    fields: [{ name: 'reason', label: 'Reason', type: 'textarea', full: true }],
    onSubmit: async (v) => {
      const reason = (v.reason || '').trim();
      await api('DELETE', `/admin/users/${u.id}${reason ? `?reason=${encodeURIComponent(reason)}` : ''}`);
      toast('Staff account removed');
      reload();
    },
  });

  const unlock = async (u) => {
    try {
      await api('POST', `/admin/users/${u.id}/unlock`);
      toast('User unlocked');
      reload();
    } catch (err) { toast(err.message, true); }
  };

  const isLocked = (u) => u.locked_until && new Date(u.locked_until) > new Date();

  return h('div', {},
    h('div', { class: 'page-head' }, h('h2', { text: plural(users.length, 'staff account') }),
      h('button', { class: 'primary', text: 'Add staff', onclick: addStaff })),
    table([
      { label: 'Name', render: (u) => h('div', {}, h('div', { text: `${u.first_name} ${u.last_name}`.trim() || u.username }), h('div', { class: 'sub', text: `${u.username} · ${u.email}` })) },
      { label: 'Role', render: (u) => u.role_name || '—' },
      { label: 'Status', render: (u) => h('div', { class: 'actions' }, pill(u.is_active ? 'ACTIVE' : 'DEACTIVATED'), isLocked(u) ? pill('LOCKED') : null) },
      { label: 'Last sign-in', render: (u) => fmt.dateTime(u.last_login_at) },
      { label: '', render: (u) => h('div', { class: 'actions' },
        u.is_active
          ? h('button', { class: 'small danger', text: 'Deactivate', onclick: () => setActive(u, false) })
          : h('button', { class: 'small', text: 'Reactivate', onclick: () => setActive(u, true) }),
        isLocked(u) ? h('button', { class: 'small', text: 'Unlock', onclick: () => unlock(u) }) : null,
        h('button', { class: 'small', text: 'Change role', onclick: () => changeRole(u) }),
        h('button', { class: 'small', text: 'Reset password', onclick: () => resetPassword(u) }),
        h('button', { class: 'small danger', text: 'Remove', onclick: () => remove(u) })) },
    ], users, { empty: 'No staff accounts.' }));
}

const KIN_RELATIONSHIPS = ['Spouse', 'Son', 'Daughter', 'Parent', 'Sibling', 'Other relative', 'Friend'];

async function farmersTab(sacco) {
  const holder = h('div', { class: 'loading', text: 'Loading…' });
  const search = h('input', { type: 'search', placeholder: 'Search name, number, phone or ID' });
  const status = h('select', {}, [['', 'All statuses'], ['ACTIVE', 'Active'], ['INACTIVE', 'Inactive'], ['SUSPENDED', 'Suspended']]
    .map(([v, l]) => h('option', { value: v, text: l })));
  let page = 1;

  const load = async () => {
    try {
      const data = await api('GET', `/admin/saccos/${sacco.id}/members${qs({ search: search.value.trim(), status: status.value, page, per_page: 25 })}`);
      holder.replaceChildren(
        table([
          { label: 'Member no.', render: (m) => m.membership_number },
          { label: 'Name', render: (m) => `${m.first_name} ${m.last_name}` },
          { label: 'Phone', render: (m) => m.phone },
          { label: 'Location', render: (m) => m.location || '—' },
          { label: 'Next of kin', render: (m) => m.next_of_kin_name
            ? h('div', {}, h('div', { text: `${m.next_of_kin_name} (${m.next_of_kin_relationship || '—'})` }), h('div', { class: 'sub', text: m.next_of_kin_phone || '' }))
            : '—' },
          { label: 'Payout', render: (m) => m.mpesa_number ? `M-Pesa ${m.mpesa_number}` : (m.bank_account_number ? `${m.bank_name || 'Bank'} ${m.bank_account_number}` : '—') },
          { label: 'Status', render: (m) => pill(m.status) },
          { label: 'Registered', render: (m) => fmt.date(m.created_at) },
        ], data.members, { empty: 'No farmers found.' }),
        pager(data.meta, (p) => { page = p; load(); }));
    } catch (err) { holder.replaceChildren(h('p', { class: 'form-error', text: err.message })); }
  };

  let timer;
  search.addEventListener('input', () => { clearTimeout(timer); timer = setTimeout(() => { page = 1; load(); }, 300); });
  status.addEventListener('change', () => { page = 1; load(); });
  load();

  const addFarmer = () => openForm({
    title: `Register a farmer for ${sacco.name}`,
    intro: 'A membership number is generated automatically unless you enter one.',
    submitLabel: 'Register farmer',
    fields: [
      { name: 'first_name', label: 'First name', required: true },
      { name: 'last_name', label: 'Last name', required: true },
      { name: 'phone', label: 'Phone', required: true, placeholder: '07XXXXXXXX' },
      { name: 'national_id', label: 'National ID' },
      { name: 'gender', label: 'Gender', type: 'select', options: [['', '—'], ['FEMALE', 'Female'], ['MALE', 'Male'], ['OTHER', 'Other']] },
      { name: 'location', label: 'Location / route' },
      { name: 'membership_number', label: 'Membership number' },
      { section: 'Next of kin' },
      { name: 'next_of_kin_name', label: 'Full name', required: true },
      { name: 'next_of_kin_relationship', label: 'Relationship', type: 'select', required: true,
        options: [['', 'Choose…'], ...KIN_RELATIONSHIPS.map((r) => [r, r])] },
      { name: 'next_of_kin_phone', label: 'Phone', required: true, placeholder: '07XXXXXXXX' },
      { section: 'Payout details' },
      { name: 'mpesa_number', label: 'M-Pesa number' },
      { name: 'mpesa_name', label: 'M-Pesa name' },
      { name: 'bank_name', label: 'Bank' },
      { name: 'bank_account_number', label: 'Account number' },
    ],
    onSubmit: async (v) => {
      const data = await api('POST', `/admin/saccos/${sacco.id}/members`, compact(v));
      toast(`Registered ${data.member.first_name} as ${data.member.membership_number}`);
      page = 1;
      load();
    },
  });

  return h('div', {},
    h('div', { class: 'page-head' }, h('div', { class: 'filters' }, search, status),
      h('button', { class: 'primary', text: 'Register farmer', onclick: addFarmer })),
    holder);
}

function activityTab(sacco) {
  return Promise.resolve(auditView({ sacco_id: sacco.id }, false));
}

function saccoErrorsTab(sacco) {
  return Promise.resolve(errorsView({ sacco_id: sacco.id }, false));
}

// ---------- logs ----------

async function saccoOptions() {
  const o = await loadOverview();
  return [['', 'All Saccos'], ...o.saccos.map((s) => [s.id, s.name])];
}

function select(options, value = '') {
  const el = h('select', {}, options.map(([v, l]) => h('option', { value: v, text: l })));
  el.value = value;
  return el;
}

/** A filterable, paginated log list. fetchPage(filters) -> { logs, meta }. */
function logList({ controls, fetchPage, columns, detail, empty }) {
  const holder = h('div', { class: 'loading', text: 'Loading…' });
  let page = 1;

  const load = async () => {
    const filters = { page, per_page: 50 };
    Object.entries(controls).forEach(([k, el]) => { filters[k] = el.value.trim(); });
    try {
      const data = await fetchPage(filters);
      holder.replaceChildren(table(columns, data.logs, { detail, empty }), pager(data.meta, (p) => { page = p; load(); }));
    } catch (err) { holder.replaceChildren(h('p', { class: 'form-error', text: err.message })); }
  };

  let timer;
  Object.values(controls).forEach((el) => {
    el.addEventListener(el.tagName === 'SELECT' || el.type === 'date' ? 'change' : 'input', () => {
      clearTimeout(timer);
      timer = setTimeout(() => { page = 1; load(); }, 300);
    });
  });
  load();
  return h('div', {}, h('div', { class: 'filters' }, Object.values(controls)), holder);
}

function dateInput(title) {
  return h('input', { type: 'date', title, attrs: { 'aria-label': title } });
}

/** One-line description of an audit entry, e.g. "password reset" or "status → SUSPENDED". */
function auditSummary(l) {
  let values = {};
  try { values = l.new_values ? JSON.parse(l.new_values) : {}; } catch { /* keep empty */ }
  if (values.change) return values.change;
  if (l.action === 'STATUS' && values.status) return `status → ${values.status}`;
  if (values.name || values.buyer_name) return values.name || values.buyer_name;
  return l.entity_id;
}

/** Lists "field: old → new" for the fields that changed between two JSON snapshots. */
function changes(oldJSON, newJSON) {
  const parse = (s) => { try { return s ? JSON.parse(s) : {}; } catch { return {}; } };
  const before = parse(oldJSON);
  const after = parse(newJSON);
  const keys = [...new Set([...Object.keys(before), ...Object.keys(after)])]
    .filter((k) => JSON.stringify(before[k]) !== JSON.stringify(after[k]));
  if (keys.length === 0) return h('span', { class: 'muted', text: 'No field changes recorded.' });
  const show = (v) => (v === undefined || v === null ? '—' : typeof v === 'object' ? JSON.stringify(v) : String(v));
  return h('dl', { class: 'kv' }, keys.flatMap((k) => [
    h('dt', { text: k }),
    h('dd', { text: oldJSON ? `${show(before[k])} → ${show(after[k])}` : show(after[k]) }),
  ]));
}

function auditView(fixed = {}, withSacco = true) {
  const controls = {};
  const holder = h('div');
  const build = (options) => {
    if (withSacco) controls.sacco_id = select(options);
    controls.entity_type = select([['', 'All records'], ['milk_collection', 'Collections'], ['milk_sale', 'Sales'], ['milk_transfer', 'Transfers'],
      ['customer', 'Customers'], ['customer_payment', 'Customer payments'], ['user', 'Users'], ['role', 'Roles'], ['sacco', 'Saccos']]);
    controls.action = select([['', 'All actions'], ['CREATE', 'Created'], ['UPDATE', 'Edited'], ['STATUS', 'Status change'], ['VOID', 'Voided'], ['DELETE', 'Removed']]);
    controls.from_date = dateInput('From date');
    controls.to_date = dateInput('To date');
    holder.replaceChildren(logList({
      controls,
      fetchPage: (f) => api('GET', `/admin/audit-logs${qs({ ...f, ...fixed })}`),
      empty: 'No audit entries match.',
      columns: [
        { label: 'When', render: (l) => fmt.dateTime(l.created_at) },
        ...(withSacco ? [{ label: 'Sacco', render: (l) => l.sacco_name || '—' }] : []),
        { label: 'Who', render: (l) => l.actor_name || '—' },
        { label: 'Record', render: (l) => h('div', {}, h('div', { text: l.entity_type.replace(/_/g, ' ') }), h('div', { class: 'sub', text: auditSummary(l) })) },
        { label: 'Action', render: (l) => pill(l.action) },
        { label: 'Reason', render: (l) => l.reason || '' },
      ],
      detail: (l) => changes(l.old_values, l.new_values),
    }));
  };
  if (withSacco) saccoOptions().then(build).catch((e) => holder.replaceChildren(h('p', { class: 'form-error', text: e.message })));
  else build();
  return holder;
}

function errorsView(fixed = {}, withSacco = true) {
  const controls = {};
  const holder = h('div');
  const build = (options) => {
    if (withSacco) controls.sacco_id = select(options);
    controls.level = select([['', 'All levels'], ['ERROR', 'Server errors (5xx)'], ['WARN', 'Client errors (4xx)']]);
    controls.search = h('input', { type: 'search', placeholder: 'Search path or message' });
    controls.from_date = dateInput('From date');
    controls.to_date = dateInput('To date');
    holder.replaceChildren(logList({
      controls,
      fetchPage: (f) => api('GET', `/admin/error-logs${qs({ ...f, ...fixed })}`),
      empty: 'No failed requests. 🎉',
      columns: [
        { label: 'When', render: (l) => fmt.dateTime(l.created_at) },
        { label: 'Status', render: (l) => pill(String(l.status), l.status >= 500 ? 'bad' : 'warn') },
        { label: 'Request', render: (l) => h('div', {}, h('div', { text: `${l.method} ${l.path}` }), h('div', { class: 'sub', text: `${l.duration_ms} ms` })) },
        { label: 'Message', render: (l) => l.message || '' },
        { label: 'User', render: (l) => h('div', {}, h('div', { text: l.username || '—' }), withSacco ? h('div', { class: 'sub', text: l.sacco_name || '' }) : null) },
      ],
      detail: (l) => h('dl', { class: 'kv' },
        h('dt', { text: 'Request ID' }), h('dd', { text: l.request_id || '—' }),
        h('dt', { text: 'Query' }), h('dd', { text: l.query || '—' }),
        h('dt', { text: 'IP' }), h('dd', { text: l.ip || '—' }),
        h('dt', { text: 'Client' }), h('dd', { text: l.user_agent || '—' }),
        h('dt', { text: 'Message' }), h('dd', { text: l.message || '—' })),
    }));
  };
  if (withSacco) saccoOptions().then(build).catch((e) => holder.replaceChildren(h('p', { class: 'form-error', text: e.message })));
  else build();
  return holder;
}

async function auditPage() {
  return h('div', {}, h('div', { class: 'page-head' }, h('h1', { text: 'Audit trail' })),
    h('p', { class: 'muted', text: 'Every create, edit, status change and void across all Saccos. Click a row to see what changed.' }),
    auditView());
}

async function errorsPage() {
  return h('div', {}, h('div', { class: 'page-head' }, h('h1', { text: 'Errors' })),
    h('p', { class: 'muted', text: 'API requests that failed (status 400 and above), kept for 30 days. Server errors (5xx) need attention; client errors (4xx) show what users struggled with.' }),
    errorsView());
}

async function smsPage() {
  const options = await saccoOptions();
  const controls = {
    sacco_id: select(options),
    status: select([['', 'All statuses'], ['SENT', 'Sent'], ['FAILED', 'Failed']]),
    search: h('input', { type: 'search', placeholder: 'Phone number' }),
    from_date: dateInput('From date'),
    to_date: dateInput('To date'),
  };
  return h('div', {}, h('div', { class: 'page-head' }, h('h1', { text: 'SMS logs' })),
    logList({
      controls,
      fetchPage: (f) => api('GET', `/admin/sms-logs${qs(f)}`),
      empty: 'No SMS messages match.',
      columns: [
        { label: 'When', render: (l) => fmt.dateTime(l.created_at) },
        { label: 'Sacco', render: (l) => l.sacco_name || '—' },
        { label: 'To', render: (l) => l.recipient_phone },
        { label: 'Status', render: (l) => pill(l.status) },
        { label: 'Message', render: (l) => h('div', {}, h('div', { text: l.message }), l.error_message ? h('div', { class: 'sub', text: l.error_message }) : null) },
        { label: 'Provider', render: (l) => l.provider },
      ],
    }));
}

window.addEventListener('hashchange', render);
render();
