(() => {
  const business = document.getElementById('business');
  const hint = document.getElementById('hint');
  const menu = document.getElementById('menu');
  const count = document.getElementById('count');
  const desktop = document.querySelector('.desktop');
  const message = document.getElementById('message');
  const actions = document.getElementById('actions');
  const orderItems = document.getElementById('orderItems');
  const orderCount = document.getElementById('orderCount');
  const orderTotal = document.getElementById('orderTotal');
  const chargeButton = document.querySelector('.chargeButton');
  const clearButton = document.querySelector('.clearButton');
  const customerModal = document.getElementById('customerModal');
  const cursor = document.getElementById('posCursor');
  const resourceName = new URLSearchParams(window.location.search).get('resource')
    || window.GetParentResourceName?.()
    || 'origen_businesses';
  const PAGE_SIZE = 4;

  const money = (value) => `$${Number(value || 0).toLocaleString('es-ES')}`;

  function sendAction(action, data = {}) {
    fetch(`https://${resourceName}/posAction`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({ action, ...data }),
    }).catch(() => {});
  }

  function card(title, detail, price, selected = false, badge = '', action = '', index = 0, image = '') {
    const element = document.createElement('article');
    element.className = `item${selected ? ' selected' : ''}${action ? ' interactive' : ''}`;
    if (!detail) element.classList.add('noDetail');
    if (action) {
      element.dataset.action = action;
      element.dataset.index = String(index);
      element.tabIndex = 0;
      element.setAttribute('role', 'button');
    }

    const heading = document.createElement('strong');
    heading.textContent = title || 'Producto';
    const description = detail ? document.createElement('small') : null;
    if (description) description.textContent = detail;
    const footer = document.createElement('div');
    footer.className = 'itemFooter';
    const amount = document.createElement('b');
    amount.textContent = price || '';
    footer.append(amount);
    if (badge) {
      const quantity = document.createElement('span');
      quantity.className = 'itemBadge';
      quantity.textContent = badge;
      footer.append(quantity);
    }
    if (image) {
      element.classList.add('hasImage');
      const productImage = document.createElement('img');
      productImage.className = 'itemImage';
      productImage.src = image;
      productImage.alt = '';
      productImage.draggable = false;
      productImage.addEventListener('error', () => productImage.remove(), { once: true });
      element.append(productImage);
    }
    element.append(heading);
    if (description) element.append(description);
    element.append(footer);
    return element;
  }

  function actionButton(label, action, disabled = false) {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'actionButton';
    button.dataset.action = action;
    button.textContent = label;
    button.disabled = disabled;
    return button;
  }

  function renderCustomerModal(data, customers) {
    customerModal.replaceChildren();
    customerModal.hidden = !data.customerModal || data.mode !== 'menu';
    if (customerModal.hidden) return;

    const selectedCustomerIndex = Math.max(1, Number(data.selectedCustomerIndex || 1));
    const pageStart = Math.floor((selectedCustomerIndex - 1) / PAGE_SIZE) * PAGE_SIZE;
    const dialog = document.createElement('section');
    dialog.className = 'customerDialog';
    dialog.setAttribute('role', 'dialog');
    dialog.setAttribute('aria-modal', 'true');
    dialog.setAttribute('aria-label', 'Asignar pedido');

    const title = document.createElement('header');
    title.className = 'customerDialogTitle';
    const titleText = document.createElement('div');
    titleText.append('ASIGNAR PEDIDO');
    const total = document.createElement('small');
    total.textContent = `Total del pedido: ${money(data.total)}`;
    titleText.append(total);
    const close = document.createElement('button');
    close.type = 'button';
    close.className = 'customerDialogClose';
    close.dataset.action = 'closeCustomerModal';
    close.setAttribute('aria-label', 'Cerrar');
    close.textContent = '×';
    title.append(titleText, close);

    const body = document.createElement('div');
    body.className = 'customerDialogBody';
    const listPane = document.createElement('section');
    listPane.className = 'customerListPane';
    const listHeading = document.createElement('div');
    listHeading.className = 'customerPaneHeading';
    const listTitle = document.createElement('span');
    listTitle.textContent = 'CLIENTES CERCANOS';
    const refresh = document.createElement('button');
    refresh.type = 'button';
    refresh.dataset.action = 'refreshCustomers';
    refresh.textContent = 'ACTUALIZAR';
    listHeading.append(listTitle, refresh);
    const list = document.createElement('div');
    list.className = 'customerList';
    customers.slice(pageStart, pageStart + PAGE_SIZE).forEach((customer, offset) => {
      const index = pageStart + offset + 1;
      const choice = document.createElement('button');
      choice.type = 'button';
      choice.className = 'customerChoice';
      choice.dataset.action = 'assignCustomer';
      choice.dataset.index = String(index);
      const identity = document.createElement('span');
      const name = document.createElement('strong');
      name.textContent = customer.name || 'Cliente';
      const detail = document.createElement('small');
      detail.textContent = `ID ${customer.serverId} · ${customer.distance} m`;
      identity.append(name, detail);
      const assign = document.createElement('b');
      assign.textContent = 'COBRAR';
      choice.append(identity, assign);
      list.append(choice);
    });
    if (!customers.length) {
      const empty = document.createElement('div');
      empty.className = 'customerEmpty';
      empty.textContent = 'No hay clientes cercanos. Introduce el ID del cliente.';
      list.append(empty);
    }
    const pages = document.createElement('div');
    pages.className = 'customerPages';
    const previous = actionButton('ANTERIOR', 'previousPage', pageStart <= 0);
    const next = actionButton('SIGUIENTE', 'nextPage', pageStart + PAGE_SIZE >= customers.length);
    pages.append(previous, next);
    listPane.append(listHeading, list, pages);

    const keypadPane = document.createElement('section');
    keypadPane.className = 'customerKeypadPane';
    const keypadHeading = document.createElement('div');
    keypadHeading.className = 'customerPaneHeading';
    keypadHeading.textContent = 'COBRAR POR ID';
    const display = document.createElement('div');
    display.className = 'manualIdDisplay';
    display.textContent = data.manualCustomerId || 'ID';
    const keypad = document.createElement('div');
    keypad.className = 'keypad';
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'BORRAR', '0', '⌫'].forEach((value) => {
      const key = document.createElement('button');
      key.type = 'button';
      key.dataset.action = value === 'BORRAR' ? 'clearCustomerId' : value === '⌫' ? 'backspaceCustomerId' : 'customerDigit';
      if (/^\d$/.test(value)) key.dataset.value = value;
      if (value === 'BORRAR') key.className = 'keypadClear';
      key.textContent = value;
      keypad.append(key);
    });
    keypadPane.append(keypadHeading, display, keypad);
    body.append(listPane, keypadPane);

    const footer = document.createElement('footer');
    footer.className = 'customerDialogFooter';
    footer.append(
      actionButton('CANCELAR', 'closeCustomerModal'),
      actionButton('COBRAR POR ID', 'manualCustomer', !/^\d+$/.test(data.manualCustomerId || '')),
    );
    dialog.append(title, body, footer);
    customerModal.append(dialog);
  }

  function renderOrder(cart, total) {
    orderItems.replaceChildren();
    const itemCount = cart.reduce((sum, item) => sum + Number(item.quantity || 0), 0);
    orderCount.textContent = String(itemCount);
    orderTotal.textContent = money(total);
    chargeButton.disabled = itemCount === 0;
    clearButton.disabled = itemCount === 0;

    if (!cart.length) {
      const empty = document.createElement('div');
      empty.className = 'orderEmpty';
      empty.textContent = 'Aún no has añadido productos';
      orderItems.append(empty);
      return;
    }

    cart.forEach((item, index) => {
      const quantity = Number(item.quantity || 0);
      const unitPrice = Number(item.price || 0);
      const row = document.createElement('article');
      row.className = 'orderLine';
      const details = document.createElement('div');
      details.className = 'orderLineDetails';
      const label = document.createElement('strong');
      label.textContent = item.label || 'Producto';
      const unit = document.createElement('span');
      unit.textContent = `${quantity} × ${money(unitPrice)}`;
      const subtotal = document.createElement('b');
      subtotal.textContent = money(quantity * unitPrice);
      const remove = document.createElement('button');
      remove.type = 'button';
      remove.className = 'removeOrderItem';
      remove.dataset.action = 'removeProduct';
      remove.dataset.index = String(index + 1);
      remove.setAttribute('aria-label', `Quitar ${item.label || 'producto'}`);
      remove.textContent = '×';
      const add = document.createElement('button');
      add.type = 'button';
      add.className = 'increaseOrderItem';
      add.dataset.action = 'increaseProduct';
      add.dataset.index = String(index + 1);
      add.setAttribute('aria-label', `Añadir otro ${item.label || 'producto'}`);
      add.textContent = '+';
      const subtract = document.createElement('button');
      subtract.type = 'button';
      subtract.className = 'decreaseOrderItem';
      subtract.dataset.action = 'decreaseProduct';
      subtract.dataset.index = String(index + 1);
      subtract.setAttribute('aria-label', `Quitar una unidad de ${item.label || 'producto'}`);
      subtract.textContent = '−';
      details.append(label, unit);
      row.append(details, subtotal, subtract, add, remove);
      orderItems.append(row);
    });
  }

  function render(data = {}) {
    const mode = data.mode || 'idle';
    const products = Array.isArray(data.menu) ? data.menu : [];
    const customers = Array.isArray(data.customers) ? data.customers : [];
    const cart = Array.isArray(data.cart) ? data.cart : [];
    const orderedCount = cart.reduce((sum, item) => sum + Number(item.quantity || 0), 0);
    const selectedIndex = Number(data.selectedIndex || 1);
    const selectedCustomerIndex = Number(data.selectedCustomerIndex || 1);
    const esBorrador = mode === 'draft';

    renderCustomerModal(data, customers);
    desktop.dataset.mode = mode;
    business.textContent = data.businessLabel || 'TPV disponible';
    hint.textContent = data.message || 'Haz clic en un producto para añadirlo al pedido.';
    renderOrder(cart, Number(data.total || 0));
    menu.replaceChildren();
    actions.replaceChildren();

    if (mode === 'receipt') {
      const receipt = document.createElement('div');
      receipt.className = 'placeholder receipt';
      receipt.textContent = `✓  FACTURA ${data.orderId || ''} ENVIADA`;
      menu.append(receipt);
      count.textContent = 'VENTA REGISTRADA';
      message.textContent = data.message || 'FACTURA ENVIADA';
      actions.append(actionButton('NUEVO PEDIDO', 'close'));
      return;
    }

    const pageStart = Math.floor((selectedIndex - 1) / PAGE_SIZE) * PAGE_SIZE;
    const pageProducts = products.slice(pageStart, pageStart + PAGE_SIZE);
    pageProducts.forEach((item, offset) => {
      const index = pageStart + offset;
      menu.append(card(
        item.label,
        '',
        money(item.price),
        false,
        '',
        esBorrador ? '' : 'addProduct',
        index + 1,
        item.image,
      ));
    });
    if (!products.length) {
      const empty = document.createElement('div');
      empty.className = 'placeholder';
      empty.textContent = 'Esta carta todavía no tiene productos.';
      menu.append(empty);
    }

    const pageCount = Math.max(1, Math.ceil(products.length / PAGE_SIZE));
    const pageLabel = `CARTA ${Math.min(pageCount, Math.ceil(selectedIndex / PAGE_SIZE))}/${pageCount}`;
    count.textContent = orderedCount
      ? `${pageLabel} · PEDIDO ${orderedCount} UDS. · ${money(data.total)}`
      : `${products.length} PRODUCTOS · ${pageLabel}`;
    message.textContent = esBorrador ? 'PEDIDO PENDIENTE' : mode === 'menu' ? 'CARTA DEL NEGOCIO' : 'TPV LISTO';
    if (!esBorrador) {
      actions.append(
        ...(pageStart > 0 ? [actionButton('ANTERIOR', 'previousPage')] : []),
        ...(pageStart + PAGE_SIZE < products.length ? [actionButton('SIGUIENTE', 'nextPage')] : []),
        actionButton('CERRAR', 'close'),
      );
    }
  }

  document.addEventListener('click', (event) => {
    const target = event.target.closest('[data-action]');
    if (!target || target.disabled) return;
    event.preventDefault();
    sendAction(target.dataset.action, {
      index: Number(target.dataset.index) || 0,
      value: target.dataset.value,
    });
  });

  window.addEventListener('message', (event) => {
    const payload = event.data || {};
    if (payload.action === 'menu') {
      render(payload.data);
    } else if (payload.action === 'cursorMode') {
      cursor.classList.toggle('active', payload.active === true);
    } else if (payload.action === 'cursor') {
      const x = Math.max(0, Math.min(window.innerWidth - 1, Number(payload.x) || 0));
      const y = Math.max(0, Math.min(window.innerHeight - 1, Number(payload.y) || 0));
      cursor.style.transform = `translate3d(${x}px, ${y}px, 0)`;
    }
  });

  render();
})();

