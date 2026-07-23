const http = require('http');

const data = JSON.stringify({
  email: `test@example.com`,
  password: 'password'
});

const req = http.request(
  {
    hostname: 'localhost',
    port: 3001,
    path: '/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': data.length,
    },
  },
  (res) => {
    let body = '';
    res.on('data', (c) => body += c);
    res.on('end', () => {
      const parsed = JSON.parse(body);
      const token = parsed.access_token;
      
      if (!token) return console.log('No token:', body);

      const postData = JSON.stringify({ content: 'Test post content' });
      const req3 = http.request({
        hostname: 'localhost',
        port: 3001,
        path: '/community/posts',
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
          'Content-Length': postData.length,
        }
      }, (res3) => {
        let body3 = '';
        res3.on('data', c => body3 += c);
        res3.on('end', () => {
          console.log('/community/posts POST Response:', res3.statusCode, body3);
        });
      });
      req3.write(postData);
      req3.end();
    });
  }
);

req.on('error', console.error);
req.write(data);
req.end();
