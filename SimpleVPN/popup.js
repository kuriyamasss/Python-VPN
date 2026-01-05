document.addEventListener('DOMContentLoaded', () => {
  const hostInput = document.getElementById('host');
  const portInput = document.getElementById('port');
  const userInput = document.getElementById('username');
  const passInput = document.getElementById('password');
  const connectBtn = document.getElementById('connectBtn');
  const disconnectBtn = document.getElementById('disconnectBtn');
  const configForm = document.getElementById('config-form');
  const statusText = document.getElementById('statusText');
  const statusDot = document.getElementById('statusDot');

  // åˆå§‹åŒ–ï¼šèŽ·å–å½“å‰çŠ¶æ€
  chrome.runtime.sendMessage({ type: 'GET_STATUS' }, (response) => {
    if (response && response.isConnected) {
      showConnectedState();
      // å¡«å……å·²ä¿å­˜çš„æ•°æ®
      hostInput.value = response.host || '';
      portInput.value = response.port || '';
      userInput.value = response.username || '';
    } else {
      // å°è¯•æ¢å¤ä¸Šæ¬¡çš„è¾“å…¥ä½†ä¸æ”¹å˜è¿žæŽ¥çŠ¶æ€
      if (response) {
        hostInput.value = response.host || '';
        portInput.value = response.port || '';
        userInput.value = response.username || '';
      }
      showDisconnectedState();
    }
  });

  connectBtn.addEventListener('click', () => {
    const host = hostInput.value.trim();
    const port = portInput.value.trim();
    const username = userInput.value.trim();
    const password = passInput.value.trim();

    if (!host || !port) {
      alert("Please enter Host and Port");
      return;
    }

    // å‘é€æ¶ˆæ¯ç»™ background
    chrome.runtime.sendMessage({
      type: 'UPDATE_PROXY',
      data: { isConnected: true, host, port, username, password }
    }, () => {
      showConnectedState();
    });
  });

  disconnectBtn.addEventListener('click', () => {
    chrome.runtime.sendMessage({
      type: 'UPDATE_PROXY',
      data: { isConnected: false }
    }, () => {
      showDisconnectedState();
    });
  });

  function showConnectedState() {
    connectBtn.style.display = 'none';
    disconnectBtn.style.display = 'block';
    configForm.style.opacity = '0.5';
    configForm.style.pointerEvents = 'none'; // ç¦ç”¨è¾“å…¥
    statusText.innerText = "Connected";
    statusDot.classList.add('active');
  }

  function showDisconnectedState() {
    connectBtn.style.display = 'block';
    disconnectBtn.style.display = 'none';
    configForm.style.opacity = '1';
    configForm.style.pointerEvents = 'auto';
    statusText.innerText = "Disconnected";
    statusDot.classList.remove('active');
  }
});
