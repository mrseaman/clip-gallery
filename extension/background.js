chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "save-to-gallery",
    title: "Save to Gallery",
    contexts: ["image"],
  });
});

chrome.contextMenus.onClicked.addListener(async (info) => {
  if (info.menuItemId !== "save-to-gallery") return;

  const { apiUrl, apiKey } = await chrome.storage.sync.get([
    "apiUrl",
    "apiKey",
  ]);

  if (!apiUrl || !apiKey) {
    chrome.notifications.create({
      type: "basic",
      iconUrl: "icon128.png",
      title: "Save to Gallery",
      message: "Please configure the API URL and key in extension options.",
    });
    return;
  }

  try {
    const response = await fetch(info.srcUrl);
    if (!response.ok) throw new Error("Failed to fetch image");
    const blob = await response.blob();

    const urlPath = new URL(info.srcUrl).pathname;
    const filename = decodeURIComponent(urlPath.split("/").pop()) || "image";

    const upload = await fetch(apiUrl, {
      method: "POST",
      headers: {
        "X-API-Key": apiKey,
        "X-Filename": filename,
        "Content-Type": blob.type || "application/octet-stream",
      },
      body: blob,
    });

    const result = await upload.json();

    if (result.ok) {
      chrome.notifications.create({
        type: "basic",
        iconUrl: "icon128.png",
        title: "Saved to Gallery",
        message: result.filename,
      });
    } else {
      throw new Error(result.error || "Upload failed");
    }
  } catch (err) {
    chrome.notifications.create({
      type: "basic",
      iconUrl: "icon128.png",
      title: "Save Failed",
      message: err.message,
    });
  }
});
