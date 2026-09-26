(()=>{const o=new URLSearchParams(location.search),c=o.get("ref")||o.get("order_nsu"),r=a=>String(a??"").replace(/[&<>"']/g,l=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"})[l]),g=a=>Number(a||0).toLocaleString("pt-BR",{style:"currency",currency:"BRL"}),d=document.querySelector("#confirmBox");function f(a){d.innerHTML=`<div class="icon">\u2715</div><h1>${a}</h1><a class="btn" href="/">VOLTAR AO SITE</a>`}async function h(){const a=await fetch("/api/registration/"+encodeURIComponent(c));return a.ok?a.json():null}async function m(){if(!c)return f("LINK INV\xC1LIDO");let a=await h();if(!a)return f("INSCRI\xC7\xC3O N\xC3O ENCONTRADA");const l="eba_cred_"+c;if(o.get("transaction_nsu")&&o.get("slug")){a.status!=="Pago"&&(d.innerHTML='<div class="icon">\u23F3</div><h1>CONFIRMANDO PAGAMENTO\u2026</h1>');try{const u=await(await fetch("/api/payment/verify",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({order_nsu:c,transaction_nsu:o.get("transaction_nsu"),slug:o.get("slug"),receipt_url:o.get("receipt_url"),capture_method:o.get("capture_method")})})).json();u.credentialUrl&&sessionStorage.setItem(l,u.credentialUrl)}catch{}a=await h()||a,history.replaceState(null,"","/confirmacao?ref="+encodeURIComponent(c))}let t=null;try{t=sessionStorage.getItem(l)}catch{}const e=a.status==="Pago",s=a.status==="Cancelado",p=(a.paymentMethod||"").includes("Presencial");let i="";e?i=`<div class="info-box paid-box"><h4>Pagamento confirmado</h4>
      <p>Tudo certo! Cada pessoa tem o pr\xF3prio QR Code, apresentado na entrada do evento.</p>
      <p>${t?"Abra as credenciais abaixo.":"As credenciais foram enviadas para o seu e-mail e tamb\xE9m ficam em \u201CJ\xE1 garanti meu ingresso\u201D, na p\xE1gina inicial."}</p></div>`:s?i=`<div class="info-box online-box"><h4>Inscri\xE7\xE3o cancelada</h4>
      <p>Se acha que isso \xE9 um engano, fale com a organiza\xE7\xE3o dos Bodes do Asfalto.</p></div>`:p?i=`<div class="info-box presencial-box"><h4>Pagamento no evento</h4>
      <p>Sua inscri\xE7\xE3o est\xE1 <strong>PENDENTE</strong> de confirma\xE7\xE3o.</p>
      <p>Realize o pagamento de <strong>${g(a.total)}</strong> diretamente para os Bodes do Asfalto.</p>
      <p>Ap\xF3s a confirma\xE7\xE3o, voc\xEA recebe por e-mail os QR Codes de acesso (um por pessoa).</p></div>`:i=`<div class="info-box online-box"><h4>Pagamento ainda n\xE3o confirmado</h4>
      <p>Se voc\xEA j\xE1 pagou, a confirma\xE7\xE3o pode levar alguns instantes. Atualize esta p\xE1gina em seguida.</p>
      <p>Se ainda n\xE3o pagou, use o bot\xE3o abaixo para concluir.</p></div>`;const n=[];e&&t&&n.push(`<a class="btn" href="${r(t)}">VER MINHAS CREDENCIAIS</a>`),e&&!t&&n.push('<a class="btn" href="/minha-inscricao">J\xC1 GARANTI MEU INGRESSO</a>'),!e&&!s&&a.checkoutUrl&&n.push(`<a class="btn" href="${r(a.checkoutUrl)}">IR PARA O PAGAMENTO</a>`),!e&&!s&&!p&&n.push(`<a class="ghost" href="/confirmacao?ref=${encodeURIComponent(a.reference)}">\u21BB ATUALIZAR STATUS</a>`),n.push(`<a class="${n.length?"ghost":"btn"}" href="/">VOLTAR AO SITE</a>`),d.innerHTML=`
    <div class="icon">${e?"\u2713":s?"\u2715":p?"\u{1F4CB}":"\u23F3"}</div>
    <h1>${e?"INSCRI\xC7\xC3O CONFIRMADA!":s?"INSCRI\xC7\xC3O CANCELADA":p?"INSCRI\xC7\xC3O REGISTRADA!":"AGUARDANDO PAGAMENTO"}</h1>
    <p class="ref">N\xBA ${r(a.reference)}</p>
    <div class="confirm-info">
      <p><strong>${r(a.fullName)}</strong></p>
      <p>Ingressos: <strong>${Number(a.quantity)}</strong></p>
      <p>Valor: <strong>${g(a.total)}</strong></p>
      <p>Status: <strong style="color:${e?"#4ade80":s?"#f87171":"#fbbf24"}">${r(a.status)}</strong></p>
    </div>
    ${i}
    <div class="confirm-actions">${n.join("")}</div>
    <a class="back-link" href="/#ingressos">\u2190 Fazer outra inscri\xE7\xE3o</a>
  `}m().catch(()=>f("ERRO AO CARREGAR"));})();
