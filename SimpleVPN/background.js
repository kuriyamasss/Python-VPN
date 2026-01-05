// åˆå§‹åŒ–çŠ¶æ€
let proxyConfig = {
  mode: "direct"
};

// ç›‘å¬æ¥è‡ª popup çš„æ¶ˆæ¯
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.type === 'UPDATE_PROXY') {
    handleProxyUpdate(request.data);
    sendResponse({status: 'success'});
  } else if (request.type === 'GET_STATUS') {
    chrome.storage.local.get(['isConnected', 'host', 'port', 'username'], (result) => {
      sendResponse(result);
    });
    return true; // å¼‚æ­¥å“åº”
  }
});

function handleProxyUpdate(data) {
  const { isConnected, host, port, username, password } = data;

  if (isConnected) {
    // è®¾ç½® Chrome ä»£ç†é…ç½®
    const config = {
      mode: "fixed_servers",
      rules: {
        singleProxy: {
          scheme: "socks5",
          host: host,
          port: parseInt(port)
        },
        bypassList: ["localhost", "127.0.0.1", "::1"]
      }
    };

    chrome.proxy.settings.set({ value: config, scope: "regular" }, () => {
      console.log("Proxy enabled:", host, port);
    });

    // å­˜å‚¨å‡­è¯ä»¥ä¾¿èº«ä»½éªŒè¯ä½¿ç”¨
    chrome.storage.local.set({ 
      isConnected: true, 
      host, 
      port, 
      username, 
      password 
    });

  } else {
    // å…³é—­ä»£ç†
    chrome.proxy.settings.set({ value: { mode: "direct" }, scope: "regular" }, () => {
      console.log("Proxy disabled");
    });
    
    chrome.storage.local.set({ isConnected: false });
  }
}

// å¤„ç†èº«ä»½éªŒè¯è¯·æ±‚ (SOCKS5 Auth)
chrome.webRequest.onAuthRequired.addListener(
  (details) => {
    return new Promise((resolve) => {
      chrome.storage.local.get(['username', 'password', 'isConnected'], (data) => {
        if (data.isConnected && details.isProxy) {
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
