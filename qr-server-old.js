const express = require('express');
const os = require('os');
const app = express();
const port = 3006;

// Get the actual network IP
function getNetworkIP() {
  const networkInterfaces = os.networkInterfaces();
  for (const [name, interfaces] of Object.entries(networkInterfaces)) {
    for (const interface of interfaces) {
      if (interface.family === 'IPv4' && !interface.internal) {
        return interface.address;
      }
    }
  }
  return '172.21.12.176'; // Fallback
}

const networkIP = getNetworkIP();

app.get('/', (req, res) => {
  const expoUrl = `exp://${networkIP}:8082`;
  const qrCodeUrl = `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${encodeURIComponent(expoUrl)}`;
  
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
        <title>🏀 Basketball Coach - QR Code</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                margin: 0;
                padding: 20px;
                background: linear-gradient(135deg, #111827 0%, #1F2937 100%);
                color: white;
                text-align: center;
                min-height: 100vh;
                display: flex;
                flex-direction: column;
                justify-content: center;
                align-items: center;
            }
            .container {
                background: rgba(255, 255, 255, 0.1);
                padding: 40px;
                border-radius: 20px;
                backdrop-filter: blur(10px);
                border: 1px solid rgba(255, 255, 255, 0.2);
                box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
            }
            h1 {
                font-size: 2.5em;
                margin-bottom: 10px;
                background: linear-gradient(45deg, #FF6B35, #F59E0B);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
                background-clip: text;
            }
            .subtitle {
                font-size: 1.2em;
                margin-bottom: 30px;
                color: #D1D5DB;
            }
            .qr-container {
                background: white;
                padding: 20px;
                border-radius: 15px;
                margin: 20px 0;
                display: inline-block;
            }
            .url {
                font-family: 'Monaco', 'Menlo', monospace;
                background: rgba(0, 0, 0, 0.3);
                padding: 15px;
                border-radius: 10px;
                margin: 20px 0;
                color: #10B981;
                font-size: 1.1em;
                word-break: break-all;
            }
            .instructions {
                color: #9CA3AF;
                font-size: 1.1em;
                max-width: 400px;
                line-height: 1.6;
            }
            .status {
                position: absolute;
                top: 20px;
                right: 20px;
                background: #10B981;
                color: white;
                padding: 8px 16px;
                border-radius: 20px;
                font-size: 0.9em;
                font-weight: 600;
            }
            .network-info {
                position: absolute;
                top: 20px;
                left: 20px;
                background: rgba(255, 107, 53, 0.2);
                color: #FF6B35;
                padding: 8px 16px;
                border-radius: 20px;
                font-size: 0.9em;
                font-weight: 600;
                border: 1px solid #FF6B35;
            }
            .refresh-btn {
                background: #FF6B35;
                color: white;
                border: none;
                padding: 12px 24px;
                border-radius: 10px;
                font-size: 1em;
                font-weight: 600;
                cursor: pointer;
                margin-top: 20px;
                transition: all 0.3s ease;
            }
            .refresh-btn:hover {
                background: #E55A2B;
                transform: translateY(-2px);
            }
        </style>
        <script>
            // Auto-refresh every 30 seconds to get updated QR code
            setTimeout(() => {
                window.location.reload();
            }, 30000);
        </script>
    </head>
    <body>
        <div class="status">🟢 Live</div>
        <div class="network-info">📡 ${networkIP}</div>
        
        <div class="container">
            <h1>🏀 Basketball Coach</h1>
            <p class="subtitle">Scan to connect your phone</p>
            
            <div class="qr-container">
                <img src="${qrCodeUrl}" alt="QR Code" />
            </div>
            
            <div class="url">${expoUrl}</div>
            
            <p class="instructions">
                📱 Open <strong>Expo Go</strong> on your phone<br>
                📷 Scan this QR code with your camera<br>
                🏀 Start dominating the court!
            </p>
            
            <button class="refresh-btn" onclick="window.location.reload()">
                🔄 Refresh QR Code
            </button>
        </div>
    </body>
    </html>
  `);
});

app.listen(port, () => {
  console.log(`🏀 QR Code ready at http://localhost:${port}`);
  console.log(`📱 Expo URL: exp://${networkIP}:8082`);
});
