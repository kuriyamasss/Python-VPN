document.addEventListener('DOMContentLoaded', () => {
  const hostInput = document.getElementById('host');
  const portInput = document.getElementById('port');
  const userInput = document.getElementById('username');
  const passInput = document.getElementById('password');
  const connectBtn = document.getElementById('connectBtn');
  const disconnectBtn = document.getElementById('disconnectBtn');
  const clearBtn = document.getElementById('clearBtn');
  const configForm = document.getElementById('configForm');
  const statusText = document.getElementById('statusText');
  const statusDot = document.getElementById('statusDot');
  const statusDetail = document.getElementById('statusDetail');
  const errorSection = document.getElementById('errorSection');
  const errorMessage = document.getElementById('errorMessage');

  // Load saved configuration on startup
  chrome.storage.local.get(['host', 'port', 'username', 'isConnected', 'error'], (data) => {
    // Restore input values
    if (data.host) hostInput.value = data.host;
    if (data.port) portInput.value = data.port;
    if (data.username) userInput.value = data.username;
    
    // Update UI based on connection status
    if (data.isConnected) {
      showConnectedState();
    } else {
      showDisconnectedState();
    }
    
    // Show error if any
    if (data.error) {
      showError(data.error);
    }
  });

  // Connect button
  connectBtn.addEventListener('click', () => {
    const host = hostInput.value.trim();
    const port = portInput.value.trim();
    const username = userInput.value.trim();
    const password = passInput.value.trim();

    if (!host) {
      showError("Please enter Server IP");
      return;
    }
    if (!port) {
      showError("Please enter Port");
      return;
    }
    if (isNaN(port) || port < 1 || port > 65535) {
      showError("Port must be between 1 and 65535");
      return;
    }

    // Send UPDATE_PROXY message to background
    chrome.runtime.sendMessage({
      type: 'UPDATE_PROXY',
      data: { isConnected: true, host, port, username, password }
    }, (response) => {
      if (response && response.status === 'success') {
        showConnectedState();
        hideError();
      } else {
        showError("Failed to connect. Check browser console for details.");
      }
    });
  });

  // Disconnect button
  disconnectBtn.addEventListener('click', () => {
    chrome.runtime.sendMessage({
      type: 'UPDATE_PROXY',
      data: { isConnected: false }
    }, (response) => {
      if (response && response.status === 'success') {
        showDisconnectedState();
        hideError();
      }
    });
  });

  // Clear button
  clearBtn.addEventListener('click', () => {
    chrome.storage.local.remove(['host', 'port', 'username', 'password', 'error']);
    hostInput.value = '';
    portInput.value = '9999';
    userInput.value = '';
    passInput.value = '';
    hideError();
  });

  function showConnectedState() {
    connectBtn.style.display = 'none';
    disconnectBtn.style.display = 'block';
    configForm.classList.add('form-disabled');
    statusText.innerText = "Connected";
    statusDot.classList.add('active');
    const host = hostInput.value || '?';
    const port = portInput.value || '?';
    statusDetail.innerText = `To: ${host}:${port}`;
  }

  function showDisconnectedState() {
    connectBtn.style.display = 'block';
    disconnectBtn.style.display = 'none';
    configForm.classList.remove('form-disabled');
    statusText.innerText = "Disconnected";
    statusDot.classList.remove('active');
    statusDetail.innerText = '';
  }

  function showError(message) {
    errorMessage.innerText = message;
    errorSection.classList.add('show');
  }

  function hideError() {
    errorSection.classList.remove('show');
    chrome.runtime.sendMessage({ type: 'CLEAR_ERROR' }).catch(() => {});
  }

  // Listen for status updates from background (optional real-time sync)
  chrome.storage.onChanged.addListener((changes, areaName) => {
    if (areaName === 'local') {
      if (changes.isConnected) {
        if (changes.isConnected.newValue) {
          showConnectedState();
        } else {
          showDisconnectedState();
        }
      }
      if (changes.error) {
        if (changes.error.newValue) {
          showError(changes.error.newValue);
        } else {
          hideError();
        }
      }
    }
  });
});
