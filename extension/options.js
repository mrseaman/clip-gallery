document.addEventListener("DOMContentLoaded", () => {
  chrome.storage.sync.get(["apiUrl", "apiKey"], (result) => {
    document.getElementById("apiUrl").value = result.apiUrl || "";
    document.getElementById("apiKey").value = result.apiKey || "";
  });

  document.getElementById("save").addEventListener("click", () => {
    chrome.storage.sync.set(
      {
        apiUrl: document.getElementById("apiUrl").value,
        apiKey: document.getElementById("apiKey").value,
      },
      () => {
        document.getElementById("status").textContent = "Saved!";
        setTimeout(() => {
          document.getElementById("status").textContent = "";
        }, 2000);
      }
    );
  });
});
