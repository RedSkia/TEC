let cart={}, totalOrders=1;
const pages = [
  {
    name: '🍽️ Menu',
    urls: [
      'https://www.mcdonalds.com/dk/da-dk/vores-menu/menuer.html'
    ]
  },
  {
    name: '🍔 Food',
    urls: [
      'https://www.mcdonalds.com/dk/da-dk/vores-menu/burgere.html',
      'https://www.mcdonalds.com/dk/da-dk/vores-menu/kylling-og-fisk.html'
    ]
  },
    {
    name: '🥖 Extras',
    urls: [
      'https://www.mcdonalds.com/dk/da-dk/vores-menu/sides-og-dips.html'
    ]
  },
  {
    name: '🥤 Drinks',
    urls: [
      'https://www.mcdonalds.com/dk/da-dk/vores-menu/kolde-drikke.html'
    ]
  },
  {
    name: '🍦 Sweets',
    urls: [
      'https://www.mcdonalds.com/dk/da-dk/vores-menu/mccafe-kaffe-og-kage.html',
      'https://www.mcdonalds.com/dk/da-dk/vores-menu/is.html'
    ]
  }
];

const proxy='https://api.allorigins.win/raw?url='; //Bypass CORS
const $ = id => document.getElementById(id); 
const productGrid=$('productGrid'),
      itemstatus=$('itemstatus'),
      cartItems=$('cartItems'),
      cartTotal=$('cartTotal'),
      checkoutBtn=$('checkoutBtn'),
      paymentOverlay=$('paymentOverlay'),
      paymentOverlayItems=$('paymentOverlayItems'),
      paymentOverlayTotal=$('paymentOverlayTotal');

// Navigation
pages.forEach((p,i)=>{
  const nav=document.createElement('div');
  nav.className='nav-item'+(i?'':' active');
  nav.innerHTML=p.name;
  nav.onclick=()=>{
    document.querySelectorAll('.nav-item').forEach(n=>n.classList.remove('active'));
    nav.classList.add('active');
    fetchProducts(p.urls);
  };
  $('navBottom').appendChild(nav);
});


// Fetch products
async function fetchProducts(urls){
  itemstatus.textContent='Loading...'; 
  productGrid.innerHTML=''; 
  $('pageTitle').textContent='Loading...';

  try{
    const results = await Promise.all(
      urls.map(u => fetch(proxy+encodeURIComponent(u)).then(r=>r.text())) //Download all context from urls & put into array
    );

    let totalItems = 0;
    results.forEach(html=>{
      const doc=new DOMParser().parseFromString(html,'text/html');
      const items=doc.querySelectorAll('.cmp-category__item');
      totalItems += items.length;

      items.forEach(it=>{
        const name=it.querySelector('.cmp-category__item-name')?.textContent;
        const img=it.querySelector('img')?.src;
        if(!name||!img) return;
        const price=(Math.random()*10+5).toFixed(2);

        const div=document.createElement('div');
        div.className='item';
        div.innerHTML=`<img src="${img}"><p>${name}</p>
          <div class="price">$${price}</div><div class="tooltip">Click to add!</div>`;
        div.onmouseenter=()=>div.querySelector('.tooltip').classList.add('show');
        div.onmouseleave=()=>div.querySelector('.tooltip').classList.remove('show');
        div.onclick=()=>{
          addToCart(name,price,img);
          const t=div.querySelector('.tooltip');
          t.textContent='Added!'; t.classList.add('show');
          setTimeout(()=>{ t.textContent='Click to add!'; t.classList.remove('show'); },800);
        };
        productGrid.appendChild(div);
      });
    });

    $('pageTitle').textContent=urls.length===1 
      ? (document.title || "McDonald's Products") 
      : "Combined Menu";
    itemstatus.textContent=`Loaded ${totalItems} items.`;
  } catch(e){
    itemstatus.textContent='Error loading items.';
  }
}


// Cart functions
function addToCart(name,price,img){ cart[name] ? cart[name].qty++ : cart[name]={qty:1,price:+price,img}; renderCart();}
function removeFromCart(name){ delete cart[name]; renderCart(); }
function changeQty(name,d){ cart[name].qty+=d; cart[name].qty<=0 ? removeFromCart(name) : renderCart(); }

function renderCart(){
  cartItems.innerHTML=''; let total=0;
  Object.keys(cart).forEach(n=>{
    const it=cart[n]; total+=it.price*it.qty;
    const div=document.createElement('div'); div.className='cart-item';
    div.innerHTML=`<span class="item-name" title="${n}">${n}</span>
                   <span class="item-qty">x${it.qty}</span>
                   <span class="item-price">$${(it.price*it.qty).toFixed(2)}</span>
                   <div class="buttons">
                     <button onclick="changeQty('${n}',1)">+</button>
                     <button onclick="changeQty('${n}',-1)">-</button>
                     <button onclick="removeFromCart('${n}')">x</button>
                   </div>`;
    cartItems.appendChild(div);
  });
  cartTotal.textContent=total?`Total: $${total.toFixed(2)}`:'';
  $('cartTitle').textContent=`Order #${totalOrders}`;
  checkoutBtn.style.display=Object.keys(cart).length?'block':'none';
  if(!Object.keys(cart).length) cartItems.innerHTML='<p style="text-align:center;">Cart is empty.</p>';
}

// Checkout
checkoutBtn.onclick=()=>{
  paymentOverlayItems.innerHTML=''; let total=0;
  Object.keys(cart).forEach(n=>{
    const it=cart[n]; total+=it.price*it.qty;
    const div=document.createElement('div'); div.className='paymentOverlay-item';
    div.innerHTML=`<img src="${it.img}">
                   <span class="item-name" title="${n}">${n}</span>
                   <span class="item-qty">x${it.qty}</span>
                   <span class="item-price">$${(it.price*it.qty).toFixed(2)}</span>`;
    paymentOverlayItems.appendChild(div);
  });
  paymentOverlayTotal.textContent=`Total: $${total.toFixed(2)}`;
  $('payBtn').style.display='block';
  paymentOverlay.style.display='flex';
}

// Pay
$('payBtn').onclick=()=>{
  alert(`Payment successful! Order #${totalOrders}`);
  cart={}; totalOrders++; paymentOverlay.style.display='none'; renderCart();
}

// Close paymentOverlay
paymentOverlay.onclick = (e) => { if(e.target===paymentOverlay) paymentOverlay.style.display='none'; }

fetchProducts(pages[0].url);