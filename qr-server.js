const express = require('express');
const os = require('os');
const app = express();
const port = 3006;

// Function to get the best network IP
function getNetworkIP() {
  const networkInterfaces = os.networkInterfaces();
  const validIPs = [];
  
  for (const [name, interfaces] of Object.entries(networkInterfaces)) {
    for (const interface of interfaces) {
      if (interface.family === 'IPv4' && !interface.internal) {
        validIPs.push({
          ip: interface.address,
          name: name,
          priority: name.includes('en0') ? 1 : name.includes('en') ? 2 : 3
        });
      }
    }
  }
  
  // Sort by priority and return the best one
  validIPs.sort((a, b) => a.priority - b.priority);
  return validIPs[0]?.ip || '172.21.12.176';
}

// Middleware to dynamically get network IP on each request
app.use((req, res, next) => {
  req.networkIP = getNetworkIP();
  next();
});

app.get('/', (req, res) => {
  const networkIP = req.networkIP;
  const expoPort = process.env.EXPO_PORT || '8082';
  const expoUrl = `exp://${networkIP}:${expoPort}`;
  const qrCodeUrl = `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${encodeURIComponent(expoUrl)}`;
  
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
        <title>Basketball Coach - Connect</title>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta http-equiv="refresh" content="30"> <!-- Auto refresh every 30 seconds -->
        <style>
            body {
                margin: 0;
                padding: 20px;
                background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
                color: white;
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                min-height: 100vh;
            }
            
            .network-info {
                position: absolute;
                top: 20px;
                right: 20px;
                background: rgba(255, 255, 255, 0.1);
                padding: 10px 20px;
                border-radius: 20px;
                backdrop-filter: blur(10px);
                font-size: 14px;
                display: flex;
                align-items: center;
                gap: 10px;
            }
            
            .status-indicator {
                width: 10px;
                height: 10px;
                background: #4ade80;
                border-radius: 50%;
                animation: pulse 2s infinite;
            }
            
            @keyframes pulse {
                0% { opacity: 1; transform: scale(1); }
                50% { opacity: 0.7; transform: scale(1.1); }
                100% { opacity: 1; transform: scale(1); }
            }
            
            .container {
                text-align: center;
                background: rgba(255, 255, 255, 0.05);
                padding: 40px;
                border-radius: 30px;
                backdrop-filter: blur(20px);
                box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
                max-width: 400px;
                width: 100%;
            }
            
            h1 {
                font-size: 2.5em;
                margin: 0 0 10px 0;
                background: linear-gradient(135deg, #ff6b35 0%, #f7931e 100%);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
            }
            
            .subtitle {
                font-size: 1.2em;
                opacity: 0.8;
                margin-bottom: 30px;
            }
            
            .qr-container {
                background: white;
                padding: 20px;
                border-radius: 20px;
                margin: 20px 0;
                box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
            }
            
            .qr-container img {
                display: block;
                width: 100%;
                height: auto;
            }
            
            .url {
                font-family: 'Courier New', monospace;
                background: rgba(255, 255, 255, 0.1);
                padding: 15px;
                border-radius: 10px;
                font-size: 1.1em;
                word-break: break-all;
                margin: 20px 0;
                border: 1px solid rgba(255, 255, 255, 0.2);
            }
            
            .instructions {
                margin-top: 30px;
                padding: 20px;
                background: rgba(255, 255, 255, 0.05);
                border-radius: 15px;
                border-left: 4px solid #ff6b35;
            }
            
            .instructions h3 {
                margin: 0 0 10px 0;
                color: #ff6b35;
            }
            
            .instructions ol {
                text-align: left;
                margin: 10px 0;
                padding-left: 20px;
            }
            
            .instructions li {
                margin: 8px 0;
                opacity: 0.9;
            }
            
            .services-status {
                margin-top: 20px;
                display: flex;
                gap: 15px;
                justify-content: center;
                flex-wrap: wrap;
            }
            
            .service {
                background: rgba(255, 255, 255, 0.1);
                padding: 10px 20px;
                border-radius: 20px;
                font-size: 0.9em;
                display: flex;
                align-items: center;
                gap: 8px;
            }
            
            .service.active::before {
                content: "✅";
            }
            
            .service.inactive::before {
                content: "❌";
            }
            
            .timestamp {
                position: absolute;
                bottom: 20px;
                left: 50%;
                transform: translateX(-50%);
                font-size: 0.8em;
                opacity: 0.5;
            }
        </style>
    </head>
    <body>
        <div class="network-info">
            <div class="status-indicator"></div>
            <span>Network: ${networkIP}</span>
        </div>
        
        <div class="container">
            <h1>🏀 Basketball Coach</h1>
            <p class="subtitle">AI-Powered Shot Analysis</p>
            
            <div class="qr-container">
                <img src="${qrCodeUrl}" alt="QR Code" />
            </div>
            
            <div class="url">${expoUrl}</div>
            
            <div class="services-status">
                <div class="service active">Backend API</div>
                <div class="service active">Expo Server</div>
                <div class="service active">QR Service</div>
            </div>
            
            <div class="instructions">
                <h3>📱 How to Connect</h3>
                <ol>
                    <li>Open Expo Go app on your phone</li>
                    <li>Scan the QR code above</li>
                    <li>Or enter the URL manually</li>
                    <li>Start analyzing your shots!</li>
                </ol>
            </div>
        </div>
        
        <div class="timestamp">Last updated: ${new Date().toLocaleTimeString()}</div>
        
        <script>
            // Auto-refresh the page every 30 seconds to update network info
            setTimeout(() => {
                window.location.reload();
            }, 30000);
            
            // Check services status
            fetch('http://localhost:3001/api/health')
                .then(res => res.json())
                .then(data => {
                    if (data.status !== 'healthy') {
                        document.querySelector('.service.active').classList.remove('active');
                        document.querySelector('.service.active').classList.add('inactive');
                    }
                })
                .catch(() => {
                    document.querySelector('.service.active').classList.remove('active');
                    document.querySelector('.service.active').classList.add('inactive');
                });
        </script>
    </body>
    </html>
  `);
});

// API endpoint to get current network info
app.get('/api/network', (req, res) => {
  const networkIP = req.networkIP;
  const expoPort = process.env.EXPO_PORT || '8082';
  
  res.json({
    networkIP,
    expoPort,
    expoUrl: `exp://${networkIP}:${expoPort}`,
    timestamp: new Date().toISOString()
  });
});

app.listen(port, () => {
  const networkIP = getNetworkIP();
  console.log(`🏀 QR Code ready at http://localhost:${port}`);
  console.log(`📱 Expo URL: exp://${networkIP}:8082`);
});
