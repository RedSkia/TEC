let cart={}, totalOrders=1;

const pages=[
  {name:'Burgers',url:'https://www.mcdonalds.com/dk/da-dk/vores-menu/burgere.html',icon:'🍔'},
  {name:'Meals',url:'https://www.mcdonalds.com/dk/da-dk/vores-menu/menuer.html',icon:'🍟'},
  {name:'Drinks',url:'https://www.mcdonalds.com/dk/da-dk/vores-menu/kolde-drikke.html',icon:'🥤'},
  {name:'Extras',url:'https://www.mcdonalds.com/dk/da-dk/vores-menu/sides-og-dips.html',icon:'🥖'},
  {name:'Desserts',url:'https://www.mcdonalds.com/dk/da-dk/vores-menu/is.html',icon:'🍦'}
];

const proxy='https://api.allorigins.win/raw?url='; //Bypass CORS
const $ = id => document.getElementById(id); 
const grid=$('productGrid'),
      itemstatus=$('itemstatus'),
      cartEl=$('cartItems'),
      cartTotal=$('cartTotal'),
      checkoutBtn=$('checkoutBtn'),
      overlay=$('overlay'),
      overlayItems=$('overlayItems'),
      overlayTotal=$('overlayTotal');

// Navigation
pages.forEach((p,i)=>{
  const nav=document.createElement('div');
  nav.className='nav-item'+(i?'':' active');
  nav.innerHTML=`<span>${p.icon}</span>${p.name}`;
  nav.onclick=()=>{ document.querySelectorAll('.nav-item').forEach(n=>n.classList.remove('active')); nav.classList.add('active'); fetchProducts(p.url); };
  $('navBottom').appendChild(nav);
});

// Fetch products
async function fetchProducts(url){
  itemstatus.textContent='Loading...'; grid.innerHTML=''; $('pageTitle').textContent='Loading...';
  try{
    const res=await fetch(proxy+encodeURIComponent(url));
    const doc=new DOMParser().parseFromString(await res.text(),'text/html');
    $('pageTitle').textContent=doc.querySelector('h1.cmp-title__text')?.textContent || "McDonald's Products";
    const items=doc.querySelectorAll('.cmp-category__item');
    items.forEach(it=>{
      const name=it.querySelector('.cmp-category__item-name')?.textContent;
      const img=it.querySelector('img')?.src;
      if(!name||!img) return;
      const price=(Math.random()*10+5).toFixed(2);
      const div=document.createElement('div');
      div.className='item';
      div.innerHTML=`<img src="${img}"><p>${name}</p><div class="price">$${price}</div><div class="tooltip">Click to add!</div>`;
      div.onmouseenter=()=>div.querySelector('.tooltip').classList.add('show');
      div.onmouseleave=()=>div.querySelector('.tooltip').classList.remove('show');
      div.onclick=()=>{
        addToCart(name,price,img);
        const t=div.querySelector('.tooltip'); t.textContent='Added!'; t.classList.add('show');
        setTimeout(()=>{ t.textContent='Click to add!'; t.classList.remove('show'); },800);
      };
      grid.appendChild(div);
    });
    itemstatus.textContent=`Loaded ${items.length} items.`;
  } catch(e){itemstatus.textContent='Error loading items.';}
}

// Cart functions
function addToCart(name,price,img){ cart[name]?cart[name].qty++:cart[name]={qty:1,price:+price,img}; renderCart();}
function removeFromCart(name){ delete cart[name]; renderCart(); }
function changeQty(name,d){ cart[name].qty+=d; cart[name].qty<=0?removeFromCart(name):renderCart(); }

function renderCart(){
  cartEl.innerHTML=''; let total=0;
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
    cartEl.appendChild(div);
  });
  cartTotal.textContent=total?`Total: $${total.toFixed(2)}`:'';
  $('cartTitle').textContent=`Order #${totalOrders}`;
  checkoutBtn.style.display=Object.keys(cart).length?'block':'none';
  if(!Object.keys(cart).length) cartEl.innerHTML='<p style="text-align:center;">Cart is empty.</p>';
}

// Checkout
checkoutBtn.onclick=()=>{
  overlayItems.innerHTML=''; let total=0;
  Object.keys(cart).forEach(n=>{
    const it=cart[n]; total+=it.price*it.qty;
    const div=document.createElement('div'); div.className='overlay-item';
    div.innerHTML=`<img src="${it.img}">
                   <span class="item-name" title="${n}">${n}</span>
                   <span class="item-qty">x${it.qty}</span>
                   <span class="item-price">$${(it.price*it.qty).toFixed(2)}</span>`;
    overlayItems.appendChild(div);
  });
  overlayTotal.textContent=`Total: $${total.toFixed(2)}`;
  $('payBtn').style.display='block';
  overlay.style.display='flex';
}

// Pay
$('payBtn').onclick=()=>{
  alert(`Payment successful! Order #${totalOrders}`);
  cart={}; totalOrders++; overlay.style.display='none'; renderCart();
}

// Close overlay
overlay.onclick=e=>{ if(e.target===overlay) overlay.style.display='none'; }

fetchProducts(pages[0].url);