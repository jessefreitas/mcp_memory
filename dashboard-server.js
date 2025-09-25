import fs from 'fs';
import http from 'http';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const port = 3000;
const server = http.createServer((req, res) => {
  if (req.url === '/' || req.url === '/dashboard') {
    fs.readFile(path.join(__dirname, 'dashboard.html'), (err, data) => {
      if (err) {
        res.writeHead(404);
        res.end('Dashboard not found');
        return;
      }
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(data);
    });
  } else {
    res.writeHead(404);
    res.end('Not found');
  }
});

server.listen(port, () => {
  console.log(`🌐 Dashboard disponível em: http://localhost:${port}`);
  console.log('🎯 Acesse /dashboard para a interface do MCP Memory Server');
});