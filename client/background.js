// Initialize state
let proxyConfig = {
  mode: "direct"
};

// Store credentials globally for auth use
let globalCredentials = {
  username: '',
  password: ''
};

// Listen for messages from popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.type === 'UPDATE_PROXY') {
    handleProxyUpdate(request.data);
    sendResponse({status: 'success'});
  } else if (request.type === 'GET_STATUS') {
    chrome.storage.local.get(['isConnected', 'host', 'port', 'username', 'error'], (result) => {
      sendResponse(result || {});
    });
    return true; // async response
  } else if (request.type === 'CLEAR_ERROR') {
    chrome.storage.local.remove(['error']);
    sendResponse({status: 'success'});
  }
});

function handleProxyUpdate(data) {
  const { isConnected, host, port, username, password } = data;

  if (isConnected) {
    // Validate input
    if (!host || !port) {
      const errorMsg = "Invalid host or port";
      chrome.storage.local.set({ error: errorMsg });
      console.error("[ERROR] " + errorMsg);
      return;
    }

    // Set Chrome proxy configuration
    const config = {
      mode: "fixed_servers",
      rules: {
        singleProxy: {
          scheme: "socks5",
          host: host,
          port: parseInt(port)
        },
        bypassList: ["localhost", "127.0.0.1", "::1", "<local>"]
      }
    };

    chrome.proxy.settings.set({ value: config, scope: "regular" }, () => {
      if (chrome.runtime.lastError) {
        const errorMsg = "Failed to set proxy: " + (chrome.runtime.lastError?.message || "Unknown error");
        chrome.storage.local.set({ error: errorMsg });
        console.error("[ERROR] " + errorMsg);
      } else {
        console.log("[SUCCESS] Proxy enabled:", host, port);
        // Clear any previous errors
        chrome.storage.local.remove(['error']);
      }
    });

    // Save credentials for authentication use
    chrome.storage.local.set({ 
      isConnected: true, 
      host, 
      port, 
      username, 
      password,
      timestamp: Date.now()
    });

  } else {
    // Disable proxy
    chrome.proxy.settings.set({ value: { mode: "direct" }, scope: "regular" }, () => {
      if (chrome.runtime.lastError) {
        console.error("[ERROR] Failed to disable proxy:", chrome.runtime.lastError);
      } else {
        console.log("[SUCCESS] Proxy disabled");
      }
    });
    
    chrome.storage.local.set({ isConnected: false });
    chrome.storage.local.remove(['error']);
  }
}

// Handle authentication requests (SOCKS5 Auth)
chrome.webRequest.onAuthRequired.addListener(
  (details) => {
    return new Promise((resolve) => {
      chrome.storage.local.get(['username', 'password', 'isConnected'], (data) => {
        if (data.isConnected && details.isProxy && data.username && data.password) {
          console.log("[AUTH] Providing SOCKS5 credentials");
          resolve({
            authCredentials: {
              username: data.username,
              password: data.password
            }
          });
        } else {
          resolve({});
        }
      });
    });
  },
  { urls: ["<all_urls>"] },
  ["blocking"]
);
