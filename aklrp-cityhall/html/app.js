console.log('[WINZ-UI] version 1.3.0-winz-view');

let open = false;
let prices = {};
let allowedPayments = [];
let winz = { isAdmin: false, pending: 0 };

// NUI open/close
window.addEventListener('message', (e) => {
  const data = e.data || {};
  if (data.action === 'open') {
    open = true;
    prices = data.prices || {};
    allowedPayments = data.payments || ['cash', 'bank'];
    winz = data.winz || { isAdmin: false, pending: 0 };

    document.getElementById('app').classList.remove('hidden');
    mountJobs(data.jobs || []);
    setPrices();
    setupWinz();
    switchTab('jobs');
  } else if (data.action === 'close') {
    closeUI();
  }
});

function setPrices(){
  const pDriver = document.getElementById('price-driver');
  const pId = document.getElementById('price-id');
  if (pDriver) pDriver.textContent = `$${prices.driver_license ?? 0}`;
  if (pId) pId.textContent = `$${prices.id_card ?? 0}`;

  document.querySelectorAll('[data-pay]').forEach(btn => {
    const method = btn.getAttribute('data-pay');
    if (!allowedPayments.includes(method)) btn.style.display = 'none';
  });
}

function mountJobs(jobs){
  const wrap = document.getElementById('jobs-list');
  wrap.innerHTML = '';
  jobs.forEach(j => {
    const el = document.createElement('div');
    el.className = 'card';
    el.innerHTML = `
      <h3>${j.label || j.name}</h3>
      <p>Set your job to <b>${j.name}</b>.</p>
      <button class="btn" data-job="${j.name}">Choose</button>
    `;
    wrap.appendChild(el);
  });
}

function post(type, body){
  fetch(`https://${GetParentResourceName()}/${type}`, {
    method: 'POST',
    headers: {'Content-Type':'application/json; charset=UTF-8'},
    body: JSON.stringify(body || {})
  }).then(r => r.json()).catch(() => {});
}

function closeUI(){
  open = false;
  document.getElementById('app').classList.add('hidden');
  post('close', {});
}

document.getElementById('btn-close').addEventListener('click', closeUI);

document.querySelectorAll('.tab').forEach(btn => {
  btn.addEventListener('click', () => switchTab(btn.dataset.tab));
});

function switchTab(name){
  document.querySelectorAll('.tab').forEach(t => t.classList.toggle('active', t.dataset.tab === name));
  document.querySelectorAll('.tabpane').forEach(p => p.classList.remove('show'));
  const pane = document.getElementById(`tab-${name}`);
  if (pane) pane.classList.add('show');
}

document.addEventListener('click', (e) => {
  const jobBtn = e.target.closest('[data-job]');
  if (jobBtn){
    const job = jobBtn.getAttribute('data-job');
    post('setJob', {job});
  }
  const buyBtn = e.target.closest('[data-buy]');
  if (buyBtn){
    const item = buyBtn.getAttribute('data-buy');
    const method = buyBtn.getAttribute('data-pay');
    post('buyItem', {item, method});
  }
});

// Escape to close
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && open) closeUI();
});

// ============ WINZ FRONTEND ============
let adminViewType = 'food';
let adminViewStatus = 'pending';

function setupWinz(){
  const adminBtn = document.getElementById('tab-admin-btn');
  if (winz.isAdmin) {
    adminBtn.style.display = '';
    mountAdminList();
  } else {
    adminBtn.style.display = 'none';
  }

  const form = document.getElementById('winz-unified-form');
  const result = document.getElementById('winz-unified-result');
  const typeSel = document.getElementById('grant-type');

  function updateGroups(){
    const t = typeSel.value;
    document.querySelectorAll('[data-type]').forEach(g => g.classList.add('hidden'));
    const active = document.querySelector(`[data-type="${t}"]`);
    if (active) active.classList.remove('hidden');

    const whyFood = form.querySelector('textarea[name="why"]');
    const causeFood = form.querySelector('textarea[name="cause_food"]');
    const reasonMoney = form.querySelector('select[name="reason"]');
    const causeMoney = form.querySelector('textarea[name="cause_money"]');

    if (t === 'money') {
      if (whyFood) whyFood.removeAttribute('required');
      if (causeFood) causeFood.removeAttribute('required');
      if (reasonMoney) reasonMoney.setAttribute('required','required');
      if (causeMoney) causeMoney.setAttribute('required','required');
    }
    if (t === 'food') {
      if (whyFood) whyFood.setAttribute('required','required');
      if (causeFood) causeFood.setAttribute('required','required');
      if (reasonMoney) reasonMoney.removeAttribute('required');
      if (causeMoney) causeMoney.removeAttribute('required');
    }
  }
  if (typeSel){ typeSel.addEventListener('change', updateGroups); updateGroups(); }

  if (form){
    form.addEventListener('submit', (ev) => {
      ev.preventDefault();
      const t = typeSel.value;
      const data = Object.fromEntries(new FormData(form).entries());
      data.amount = Number(data.amount || 0);
      result.textContent = 'Submitting...';

      if (t === 'money'){
        const payload = {
          fullname: data.fullname || '',
          reason: data.reason || '',
          amount: data.amount,
          cause: data.cause_money || ''
        };
        fetch(`https://${GetParentResourceName()}/winzMoneySubmit`, {
          method: 'POST',
          headers: {'Content-Type':'application/json; charset=UTF-8'},
          body: JSON.stringify(payload)
        }).then(r => r.json()).then(res => {
          if (res && res.ok){ result.textContent = res.msg || 'Submitted.'; form.reset(); updateGroups(); }
          else { result.textContent = (res && res.msg) || 'Submit failed.'; }
        }).catch(() => result.textContent = 'Submit failed.');
      } else {
        const payload = {
          fullname: data.fullname || '',
          why: data.why || '',
          cause: data.cause_food || '',
          amount: data.amount
        };
        fetch(`https://${GetParentResourceName()}/winzSubmit`, {
          method: 'POST',
          headers: {'Content-Type':'application/json; charset=UTF-8'},
          body: JSON.stringify(payload)
        }).then(r => r.json()).then(res => {
          if (res && res.ok){ result.textContent = res.msg || 'Submitted.'; form.reset(); updateGroups(); }
          else { result.textContent = (res && res.msg) || 'Submit failed.'; }
        }).catch(() => result.textContent = 'Submit failed.');
      }
    });
  }

  const refresh = document.getElementById('refresh-pending');
  if (refresh){ refresh.addEventListener('click', mountAdminList); }

  const btnFood = document.getElementById('filter-food');
  const btnMoney = document.getElementById('filter-money');
  function setFilter(type){
    adminViewType = type;
    mountAdminList();
  }
  if (btnFood) btnFood.addEventListener('click', () => setFilter('food'));
  if (btnMoney) btnMoney.addEventListener('click', () => setFilter('money'));

  const btnPending = document.getElementById('filter-pending');
  const btnApproved = document.getElementById('filter-approved');
  const btnDenied = document.getElementById('filter-denied');

  function setStatusFilter(status){
    adminViewStatus = status;
    mountAdminList();
  }

  if (btnPending) btnPending.addEventListener('click', () => setStatusFilter('pending'));
  if (btnApproved) btnApproved.addEventListener('click', () => setStatusFilter('approved'));
  if (btnDenied) btnDenied.addEventListener('click', () => setStatusFilter('denied'));
}

function mountAdminList(){
  console.log('[WINZ-UI] mountAdminList', adminViewStatus, adminViewType);
  fetch(`https://${GetParentResourceName()}/winzAdminList`, {
    method: 'POST',
    headers: {'Content-Type':'application/json; charset=UTF-8'},
    body: JSON.stringify({status: adminViewStatus, type: adminViewType})
  }).then(r => r.json()).then(data => {
    const list = document.getElementById('admin-list');
    list.innerHTML = '';
    if (!data || !data.ok || !Array.isArray(data.rows) || data.rows.length === 0){
      list.innerHTML = '<div class="muted">No applications.</div>';
      return;
    }
    data.rows.forEach(row => {
      const item = document.createElement('div');
      item.className = 'row';
      const phone = row.phone ? ` • ${row.phone}` : '';

      let statusTag = '';
      if (row.status === 'approved') {
        statusTag = `<span style="color:#55ff55;font-weight:bold">[APPROVED]</span>`;
      } else if (row.status === 'denied') {
        statusTag = `<span style="color:#ff5555;font-weight:bold">[DENIED]</span>`;
      } else {
        statusTag = `<span style="color:#ffaa00;font-weight:bold">[PENDING]</span>`;
      }

      let denyLine = '';
      if (row.status === 'denied' && row.deny_reason) {
        denyLine = `<div class="muted" style="color:#ff7777">Reason: ${row.deny_reason}</div>`;
      }

      item.innerHTML = `
        <div class="row-main">
          <div><b>#${row.id}</b> — ${row.fullname} • $${row.amount}${phone} ${statusTag}</div>
          <div class="muted">${row.citizenid || ''}</div>
          ${denyLine}
        </div>
        <div class="row-actions">
          <button class="btn info" data-view="${row.id}">View</button>
          <button class="btn" data-approve="${row.id}">Approve</button>
          <button class="btn danger" data-deny="${row.id}">Deny</button>
        </div>
      `;
      list.appendChild(item);
    });
  }).catch(err => { console.error('mountAdminList fetch error', err); });
}

document.addEventListener('click', (e) => {
  const approve = e.target.closest('[data-approve]');
  const deny = e.target.closest('[data-deny]');
  const view = e.target.closest('[data-view]');

  if (approve || deny){
    const id = Number((approve || deny).getAttribute(approve ? 'data-approve' : 'data-deny'));
    let action = approve ? 'approve' : 'deny';
    let reason = null;

    if (deny){
      reason = prompt("Enter denial reason:");
      if (!reason) reason = "No reason provided";
    }

    fetch(`https://${GetParentResourceName()}/winzAdminAction`, {
      method: 'POST',
      headers: {'Content-Type':'application/json; charset=UTF-8'},
      body: JSON.stringify({id, action, type: adminViewType, reason})
    }).then(r => r.json()).then(() => {
      mountAdminList();
      document.getElementById('admin-detail').classList.add('hidden');
    }).catch(err => console.error('adminAction fetch error', err));
  }

  if (view){
    const id = Number(view.getAttribute('data-view'));
    fetch(`https://${GetParentResourceName()}/winzGetApplication`, {
      method: 'POST',
      headers: {'Content-Type':'application/json; charset=UTF-8'},
      body: JSON.stringify({id, type: adminViewType})
    }).then(r => r.json()).then(data => {
      const detail = document.getElementById('admin-detail');
      if (!data || !data.ok || !data.app) {
        detail.innerHTML = '<div class="muted">Failed to load application.</div>';
      } else {
        const app = data.app;
        let extra = '';
        if (adminViewType === 'food') {
          extra = `
            <p><b>Why need food:</b> ${app.why_need || ''}</p>
            <p><b>What left short:</b> ${app.what_left_short || ''}</p>
            <p><b>Phone:</b> ${app.phone || ''}</p>`;
        } else {
          extra = `
            <p><b>Reason:</b> ${app.purpose || ''}</p>
            <p><b>What left short:</b> ${app.what_left_short || ''}</p>`;
        }
        let denyInfo = '';
        if (app.status === 'denied' && app.deny_reason) {
          denyInfo = `<p style="color:#ff5555"><b>Denied Reason:</b> ${app.deny_reason}</p>`;
        }
        detail.innerHTML = `
          <h3>Application #${app.id}</h3>
          <p><b>Name:</b> ${app.fullname}</p>
          <p><b>Amount:</b> $${app.amount}</p>
          ${extra}
          ${denyInfo}
          <div class="row-actions" style="margin-top:8px">
            <button class="btn" data-approve="${app.id}">Approve</button>
            <button class="btn danger" data-deny="${app.id}">Deny</button>
            <button class="btn info" id="close-detail">Close</button>
          </div>
        `;
      }
      detail.classList.remove('hidden');
    }).catch(err => { console.error('getWinzApplication fetch error', err); });
  }

  if (e.target && e.target.id === 'close-detail'){
    document.getElementById('admin-detail').classList.add('hidden');
  }
});
