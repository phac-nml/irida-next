function updateSessionStorageItem() {
  const storageKey = this.getAttribute("storage_key");
  const storageValue = this.getAttribute("storage_value");
  const tmp = JSON.parse(sessionStorage.getItem(storageKey));
  const index = tmp.indexOf(storageValue);

  if (index > -1) {
    tmp.splice(index, 1);
  }

  sessionStorage.setItem(storageKey, JSON.stringify(tmp));
}
Turbo.StreamActions.update_session_storage_item = updateSessionStorageItem;
