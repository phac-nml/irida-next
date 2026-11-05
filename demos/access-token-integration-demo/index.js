// Opens the integration access token popup and logs the returned token.
const targetOrigin = "http://localhost:3000";
const url = `${targetOrigin}/integration_access_token?caller=bdip_sheets`;

document.getElementById("inxt-btn").addEventListener("click", () => {
  const x = window.screenX || window.screenLeft || 0;
  const y = window.screenY || window.screenTop || 0;
  const options = `width=500,height=800,top=${y},left=${x}`;
  const popup = window.open(url, "access-token-popup", options);

  if (!popup) console.warn("Popup blocked");
});

window.addEventListener("message", (event) => {
  if (event.origin !== targetOrigin) return;

  console.log("Received token:", event.data);
});
